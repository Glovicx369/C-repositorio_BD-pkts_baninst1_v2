DROP PACKAGE BODY BANINST1.PKG_FEA;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_FEA  AS
 
   output_string      VARCHAR2 (200);
   encrypted_raw      RAW (2000);             -- stores encrypted binary text
   decrypted_raw      RAW (2000);             -- stores decrypted binary text
   num_key_bytes      NUMBER := 256/8;        -- key length 256 bits (32 bytes)
   key_bytes_raw      RAW (32);               -- stores 256-bit encryption key
  
  v_key RAW(16) := null;
   encryption_type    PLS_INTEGER :=          -- total encryption type
                            DBMS_CRYPTO.ENCRYPT_AES256
                          + DBMS_CRYPTO.CHAIN_CBC
                          + DBMS_CRYPTO.PAD_PKCS5;
     
     
 
cursor c_materias (vpidm varchar2, periodo  varchar2, parte varchar2)  is
select substr(stvterm_desc,1,6) periodo,  SSBSECT_ENRL total_alum, SSBSECT_CRN grupo,SSBSECT_PTRM_END_DATE fecha_fin, scbcrse_subj_code||scbcrse_crse_numb  materia
from  ssbsect, scbcrse, sirasgn, stvterm
where sirasgn_term_code= periodo 
and     sirasgn_pidm=vpidm----fget_pidm(vpidm)
and     stvterm_code=sirasgn_term_code
and     ssbsect_term_code=sirasgn_term_code
and     ssbsect_crn=sirasgn_crn
and     ssbsect_ptrm_code=parte
and     scbcrse_subj_code=ssbsect_subj_code
and     SIRASGN_PRIMARY_IND = 'Y'
and     scbcrse_crse_numb=ssbsect_crse_numb
order by sirasgn_pidm;  
   
   
   
    Function encrypt( p_data IN VARCHAR2 ) Return RAW DETERMINISTIC
    IS
  
BEGIN
   DBMS_OUTPUT.PUT_LINE ( 'Original string: ' || p_data);
   key_bytes_raw := DBMS_CRYPTO.RANDOMBYTES (num_key_bytes);
   encrypted_raw := DBMS_CRYPTO.ENCRYPT
      (
         src => UTL_I18N.STRING_TO_RAW (p_data,  'AL32UTF8'),
         typ => encryption_type,
         key => key_bytes_raw
      );
      
      dbms_output.put_line(encrypted_raw);
       -- The encrypted value "encrypted_raw" can be used here
   
    
      Return encrypted_raw;
      EXCEPTION 
        WHEN OTHERS THEN
          -- for the security reason I want to completely silence the error 
          -- stack that could reveal some technical details to imaginary attacker.
          -- Remember, such miss-use of WHEN OTHERS should be considered 
          -- as a bug in almost all other situations.
          RAISE_APPLICATION_ERROR(-20001,sqlerrm);
    END encrypt;
 
    Function decrypt( p_data IN RAW ) Return VARCHAR2 DETERMINISTIC
    IS
      l_decrypted RAW(2048);
       output_string      VARCHAR2 (200);
   encrypted_raw      RAW (2000);             -- stores encrypted binary text
   decrypted_raw      RAW (2000);             -- stores decrypted binary text
    BEGIN
     decrypted_raw := DBMS_CRYPTO.DECRYPT
      (
         src => p_data,
         typ => encryption_type,
         key => key_bytes_raw
      );
   output_string := UTL_I18N.RAW_TO_CHAR (decrypted_raw, 'AL32UTF8');
 
   DBMS_OUTPUT.PUT_LINE ('Decrypted string: ' || output_string);

  END decrypt;



Procedure P_INICIO_PROC (p_id_docente  VARCHAR2,  p_ciclo  varchar2, p_parte varchar2 , p_user  varchar2)  Is

 v_crypo RAW(2048) ;
 
v_pidm          number;
v_materno_alumn varchar2(250);
v_no_apelld     number;
v_paterno       varchar2(100);

v_no_apelld2    number;
v_materno_alumn2    varchar2(100);
v_nombre        varchar2(100);
v_siglas        varchar2(4);
v_cve_empl      varchar2(12);
v_program_desc  varchar2(80);
v_programa      varchar2(12);
v_no_rvoe       varchar2(15);
vmsjerror       varchar2(850);
v_total_alum    number;
v_grupo         number;
v_fin_curso     varchar2(14);

v_largo_text    varchar2(3600);
v_periodo varchar2(12);
v_materia varchar2(12);
--v_grupo   varchar2(12);


BEGIN
NULL;
 v_pidm := fget_pidm(p_ID_DOCENTE);
 
 for jump in c_materias(v_pidm , p_ciclo, p_parte)  loop
 -- SSBSECT_ENRL total_alum, SSBSECT_CRN grupo,SSBSECT_PTRM_END_DATE fecha_fin, scbcrse_subj_code||scbcrse_crse_numb  materia
     v_periodo := jump.periodo;
     v_materia := jump.materia;
     v_grupo   := jump.grupo;
     v_total_alum := jump.total_alum;
     v_fin_curso:= jump.fecha_fin;
      
end loop; 
 
  
begin
select DISTINCT SPBPERS_LEGAL_NAME --upper(S.SPRIDEN_LAST_NAME) , UPPER(S.SPRIDEN_FIRST_NAME),
        -- to_char(sp.SPBPERS_BIRTH_DATE, 'YYYY-MM-DD')||'T'||to_char(sp.SPBPERS_BIRTH_DATE, 'HH24:MI:SS') as fech_nac
      -- ,S.SPRIDEN_ID  , SB.SGBSTDN_CAMP_CODE
into   v_materno_alumn  ---, v_fech_nac_alumn,v_nu_control, v_campus
from spriden s, spbpers sp
where spriden_pidm = v_pidm
and  S.SPRIDEN_PIDM = SP.SPBPERS_PIDM
AND  S.SPRIDEN_CHANGE_IND IS NULL
;


exception when others then
v_materno_alumn  := '';
----vmsjerr  :=   SQLERRM;
  vmsjerror := 'Se presento un Error Spriden>  '||sqlerrm;
  dbms_output.put_line(vmsjerror);

end;


---------separa  los apellidos an dos-----
v_no_apelld  := instr(v_materno_alumn, ' ');
v_paterno  := substr(v_materno_alumn,1,v_no_apelld-1);
--dbms_output.put_line( ' paterno  ' || v_paterno_alumn || '-'|| v_no_apelld);
v_no_apelld2 := instr(v_materno_alumn, ' ',1,2);
v_materno_alumn2 := substr(v_materno_alumn, v_no_apelld+1,v_no_apelld2-v_no_apelld-1  );

--dbms_output.put_line( ' MATERNO  ' || v_materno_alumn2 || '-'|| v_no_apelld);
v_nombre  := substr(v_materno_alumn, v_no_apelld2+1,50);
--dbms_output.put_line( ' NOMBRE  ' || v_nombre_alumn || '-'|| v_no_apelld2);

dbms_output.put_line(v_materno_alumn);


v_siglas :=substr(v_paterno,1,1)|| substr(v_materno_alumn2,1,1)|| substr(v_nombre,1,1);

dbms_output.put_line(v_siglas);

begin
 select GORADID_ADDITIONAL_ID
 into v_cve_empl
 from GORADID
 where GORADID_ADID_CODE = 'RRHH'
 and  GORADID_PIDM = v_pidm
  ;
exception when others then
v_cve_empl := '00000';

end;

begin

 select distinct(SMRPRLE_PROGRAM_DESC),SMRPRLE_PROGRAM
   INTO  v_program_desc, v_programa
 From   smrpaap p, 
        smrarul u,
        SMRPRLE sm
 where   u.smrarul_area=p.smrpaap_area 
         AND u.smrarul_term_code_eff=p.smrpaap_term_code_eff
         and  P.SMRPAAP_PROGRAM  = sm.SMRPRLE_PROGRAM
         and  U.SMRARUL_SUBJ_CODE||u.SMRARUL_CRSE_NUMB_LOW  =  v_materia
         and rownum < 2  ;

exception when no_data_found then

v_program_desc:='';
v_programa    := '';

end;


begin

select distinct zt.SZTDTEC_NUM_RVOE as numrvoe
into v_no_rvoe
from sztdtec zt
where  SZTDTEC_PROGRAM    = v_programa
--and SZTDTEC_CAMP_CODE  = v_campus
;

exception when others then 
v_no_rvoe:='';


end;


--begin
--
--select SSBSECT_ENRL, SSBSECT_CRN ,SSBSECT_PTRM_END_DATE  ------se toma el ENRL  como total de alumnos y CRN  como num de grupo y end_date como termino del curso
--INTO  v_total_alum , v_grupo, v_fin_curso
--from SSBSECT
--where SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB = p_code_materia
--and SSBSECT_TERM_CODE = p_ciclo 
--and  SSBSECT_CRN    =   p_grupo 
--;
--
--exception when others then 
--v_total_alum := 0;
--
--end;



dbms_output.put_line('salida'|| v_pidm ||'--'||v_materno_alumn ||'--'||v_siglas ||'--'||v_cve_empl||'--'||v_program_desc||'-'||v_programa||'--'||v_no_rvoe||'-'||
 v_total_alum||'--'|| v_grupo||'--'|| v_fin_curso );

v_largo_text :=  v_pidm ||'|'||v_materno_alumn ||'|'||v_siglas ||'|'||v_cve_empl||'|'||v_program_desc||'|'||v_no_rvoe||'|'||
v_total_alum||'|'|| v_grupo||'|'|| v_fin_curso||'|'||v_materia;

v_crypo:= encrypt( v_largo_text );

dbms_output.put_line(v_crypo);


p_code_qr(p_id_docente,v_materia,p_ciclo,v_grupo,v_fin_curso,  v_largo_text , v_crypo,p_user  );

END P_INICIO_PROC;


procedure  p_code_qr(p_id_docente  VARCHAR2,p_code_materia  varchar2 , p_ciclo  varchar2, v_grupo  varchar2,v_fin_curso  varchar2, pdatos  varchar2, pdatosqr  varchar2 ,p_user varchar2) is


V_BLOB         BLOB;
V_BFILE        BFILE;
salida         UTL_FILE.FILE_TYPE  ;
nom_archivo    varchar2(150);
directorio     varchar2(90);
mserr          varchar2(2000);
V_OFFSET       NUMBER:=1;
 

BEGIN

select baninst1.MAKE_QR.qr_bin(pdatos) 
into V_BLOB
 from dual;

--lect baninst1.MAKE_QR.qr_bin('Any text to encode QR code') from dual;

insert into SZTACTAQR ( SZTACTAQR_ID_DOCENTE, SZTACTAQR_PERIODO, SZTACTAQR_MATERIA,SZTACTAQR_GRUPO,
SZTACTAQR_FECHA_TERMINO, SZTACTAQR_CODE_QR,SZTACTAQR_TEXT_CRYPTO, SZTACTAQR_TEXT_VALOR ,SZTACTAQR__ACTIVITY_DATE,SZTACTAQR_USER )
values(p_id_docente,p_ciclo, p_code_materia,v_grupo,v_fin_curso, V_BLOB, pdatosqr, pdatos, sysdate, p_user ) returning SZTACTAQR_CODE_QR into V_BLOB  ;
--
 --dbms_output.put_line(' salida archivo DGAIR-------  '|| ppidalumno); 

nom_archivo := 'QR_'||p_id_docente||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')||'.jpg';
-- dbms_output.put_line(' nomnbrev  archivo DGAIR-------  '|| nom_archivo); 
 salida := UTL_FILE.fopen('ARCHXML',nom_archivo, 'WB', 32767);
     UTL_FILE.PUT_RAW(SALIDA,DBMS_LOB.SUBSTR(V_BLOB,32767,V_OFFSET));
     V_OFFSET  := V_OFFSET+32767;
    UTL_FILE.fclose(salida);
 IF utl_file.is_open(salida) THEN
     utl_file.fclose_all;
     dbms_output.put_line('Closed All');
   END IF;
 

commit;

end  p_code_qr;



BEGIN

NULL;

exception when others then
null;

end PKG_FEA;
/

DROP PUBLIC SYNONYM PKG_FEA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FEA FOR BANINST1.PKG_FEA;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_FEA TO PUBLIC;
