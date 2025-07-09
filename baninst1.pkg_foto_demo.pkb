DROP PACKAGE BODY BANINST1.PKG_FOTO_DEMO;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_foto_demo
/* se corrige faltas de ortografia " Ültimo periodo Inscripción"   realiza glovicx 09/11/2018 */
AS
FUNCTION base64encode(
p_blob IN BLOB)
RETURN CLOB
IS
l_clob CLOB;
l_step PLS_INTEGER := 24573; -- make sure you set a multiple of 3 not higher than 24573
BEGIN
FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_blob) - 1 )/l_step)
LOOP
l_clob:=l_clob||UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_blob, l_step, i * l_step + 1)));
--l_clob := UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_blob, l_step, i * l_step + 1)));
--HTP.P (l_clob);
END LOOP;
RETURN l_clob;
END;
--
PROCEDURE get_img_from_fs(
p_dir IN VARCHAR2,
p_file IN VARCHAR2)
AS
l_bfile BFILE;
l_blob BLOB;
BEGIN
INSERT
INTO szrimag (
szrimag_id,
szrimag_image )
VALUES (
p_file,
empty_blob() )
RETURN szrimag_image
INTO l_blob;
l_bfile := BFILENAME(p_dir, p_file || '.jpg');
DBMS_LOB.fileopen(l_bfile, DBMS_LOB.file_readonly);
DBMS_LOB.loadfromfile(l_blob, l_bfile, DBMS_LOB.getlength(l_bfile));
DBMS_LOB.fileclose(l_bfile);
COMMIT;
END;
--
PROCEDURE put_img_to_fs
(
p_dir IN VARCHAR2,
p_file IN VARCHAR2
)
AS
t_blob BLOB;
t_len NUMBER;
t_file_name VARCHAR2(100);
t_output UTL_FILE.file_type;
t_TotalSize NUMBER;
t_position NUMBER := 1;
t_chucklen NUMBER := 4096;
t_chuck raw(4096);
t_remain NUMBER;
BEGIN
-- Get length of blob
SELECT DBMS_LOB.getlength (szrimag_image),
szrimag_id
||'.jpg'
--|| '_1.jpg'
INTO t_TotalSize,
t_file_name
FROM szrimag
WHERE szrimag_id =p_file;
t_remain := t_TotalSize;
-- The directory TEMPDIR should exist before executing
t_output := UTL_FILE.fopen (p_dir, t_file_name, 'wb', 32760);
-- Get BLOB
SELECT szrimag_image
INTO t_blob
FROM szrimag
WHERE szrimag_id =p_file;
-- Retrieving BLOB
WHILE t_position < t_TotalSize
LOOP
DBMS_LOB.READ (t_blob, t_chucklen, t_position, t_chuck);
UTL_FILE.put_raw (t_output, t_chuck);
UTL_FILE.fflush (t_output);
t_position := t_position + t_chucklen;
t_remain := t_remain - t_chucklen;
IF t_remain < 4096 THEN
t_chucklen := t_remain;
END IF;
END LOOP;
UTL_FILE.fclose(t_output);
END;
--
PROCEDURE get_enc_img_from_fs(
p_dir IN VARCHAR2,
p_file IN VARCHAR2,
p_clob IN OUT NOCOPY CLOB)
AS
l_bfile BFILE;
l_step PLS_INTEGER := 1200;
BEGIN
l_bfile := BFILENAME(p_dir, p_file);
DBMS_LOB.fileopen(l_bfile, DBMS_LOB.file_readonly);
FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(l_bfile) - 1 )/l_step)
LOOP
p_clob := p_clob || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(l_bfile, l_step, i * l_step + 1)));
--p_clob := UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_clob, l_step, i * l_step + 1)));
--HTP.P (p_clob);

END LOOP;
DBMS_LOB.fileclose(l_bfile);
END;
--
PROCEDURE get_enc_img_from_http(
p_url IN VARCHAR2,
p_clob IN OUT NOCOPY CLOB)
AS

        l_clob CLOB;
        l_step PLS_INTEGER := 24573; -- make sure you set a multiple of 3 not higher than 24573  
  BEGIN
  -- p_clob := p_clob || base64encode(HTTPURITYPE.createuri(p_url).getblob());
   FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_clob) - 1 )/l_step)
   LOOP
        l_clob:=l_clob||UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_clob, l_step, i * l_step + 1)));
       -- l_clob := UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_clob, l_step, i * l_step + 1)));
       --HTP.P (l_clob);
END LOOP;

END;
--
PROCEDURE get_enc_img_from_tab(
p_image_id IN VARCHAR2,
p_clob IN OUT NOCOPY CLOB)
AS
BEGIN
SELECT p_clob
|| base64encode(szrimag_image)
INTO p_clob
FROM szrimag
WHERE szrimag_id = p_image_id;
END;
--
--
--
PROCEDURE p_pagina0
IS
l_image BLOB;
BEGIN
SELECT szrimag_image
INTO l_image
FROM szrimag
WHERE szrimag_id = 'j' FOR UPDATE;
-- first clear the header
htp.flush;
htp.init;
-- set up HTTP header
--owa_util.mime_header('application/pdf',false);
-- set the size so the browser knows how much to download
htp.p('Content-Length: ' || dbms_lob.getlength(l_image));
-- the filename will be used by the browser if the users does a save as
--htp.p('Content-Disposition:attachment; filename="pagare.pdf"');
htp.p('Content-Disposition:inline; filename="j.jpg"');
-- Set COOKIE (for javascript download plugin)
--* htp.p('Set-Cookie: fileDownload=true; path=/');
-- close the headers
owa_util.http_header_close;
-- download the BLOB
wpg_docload.download_file(l_image);
END;
--
PROCEDURE p_pagina11
IS
l_image BLOB;
BEGIN
SELECT szrimag_image
INTO l_image
FROM szrimag
WHERE szrimag_id = 'j' FOR UPDATE;
-- first clear the header
htp.flush;
htp.init;
-- set up HTTP header
owa_util.mime_header('image/bmp',false);
-- set the size so the browser knows how much to download
htp.p('Content-Length: ' || dbms_lob.getlength(l_image));
-- the filename will be used by the browser if the users does a save as
htp.p('Content-Disposition:attachment; filename="foto.bmp"');
--** htp.p('Content-Disposition:inline; filename="fotografia.jpg"');
-- Set COOKIE (for javascript download plugin)
--* htp.p('Set-Cookie: fileDownload=true; path=/');
-- close the headers
owa_util.http_header_close;
-- download the BLOB
wpg_docload.download_file(l_image);
END;
--
/*
PROCEDURE p_pagina2
IS
l_clob CLOB;
BEGIN
DBMS_LOB.createtemporary(l_clob, FALSE);
-- Build the start of the HTML document, including the start of the IMG tag
-- and place it in a CLOB.
--l_clob := ok 
--'<html>
--<head>
--<title>Test HTML with Embedded Image</title>
--</head>
--<body>
--<BR CLEAR=RIGHT>
--'<img src="data:image/gif;base64,';   ok
--get_enc_img_from_tab (p_image_id => 'joto', p_clob => l_clob); ok
--l_clob := l_clob || '" alt="Fotografia" />';  ok
--<br>
--</body>
--</html>';
-- The CLOB now contains the complete HTML with the embedded image, so do something with it.
-- In this case I'm going to write it to the file system.
-- create_file_from_clob (p_dir => 'IMAGES', p_file => 'EmbeddedImageTest.htm', p_clob => l_clob);
htp.p(l_clob);
DBMS_LOB.freetemporary(l_clob);
EXCEPTION
WHEN OTHERS THEN
DBMS_LOB.freetemporary(l_clob);
RAISE;
END;
*/


FUNCTION f_my_proceedafterlogin(
      pidm        IN NUMBER,
      return_code IN VARCHAR2)
    RETURN VARCHAR2
    IS
    -- lv_url  varchar2(100) := twbkwbis.f_cgibin || 'bwskgstu.P_StuInfo';
    --lv_url  varchar2(500) := twbkwbis.f_cgibin || 'pkg_foto_demo.p_pagina1';   ------------se cambio esta URL para cambiar la pagina de inicio del SSB glovicx 0504019
    lv_url  varchar2(500) := twbkwbis.f_cgibin || 'twbkwbis.P_GenMenu?name=bmenu.P_Protocol';
  BEGIN 
   return (lv_url);
  END;

  PROCEDURE p_pagina1
  IS
    l_pidm NUMBER;  
    l_clob  CLOB;
    --
    nombre varchar2(80);
    matricula varchar2(9);

    FUNCTION base64encode (p_blob IN BLOB)
      RETURN CLOB  
    IS
      l_clob CLOB;
      l_step PLS_INTEGER := 1200000;
    BEGIN
      FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_blob) - 1 )/l_step) LOOP
        l_clob := l_clob || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_blob, l_step, i * l_step + 1)));
        --l_clob := UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_blob, l_step, i * l_step + 1)));
       --HTP.P (l_clob);
      END LOOP;
      RETURN l_clob;
    END;

    --

    PROCEDURE get_enc_img_from_http (p_url  IN VARCHAR2,
                                     p_clob IN OUT NOCOPY CLOB)
    AS
    
        l_clob CLOB;
        l_step PLS_INTEGER := 24573; -- make sure you set a multiple of 3 not higher than 24573  

  BEGIN
   p_clob := p_clob || base64encode(HTTPURITYPE.createuri(p_url).getblob());
   FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_clob) - 1 )/l_step)
   LOOP
        l_clob:=l_clob||UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_clob, l_step, i * l_step + 1)));
        --l_clob := UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_clob, l_step, i * l_step + 1)));
       --HTP.P (l_clob);
        
END LOOP;
   
   
  end;
    
    --
begin
    IF NOT twbkwbis.F_ValidUser(l_pidm) THEN
      RETURN;
    END IF;
    
    begin
    select spriden_id, spriden_last_name||' '||spriden_first_name into  matricula,nombre
    from spriden
    where spriden_pidm=l_pidm
    and     spriden_change_ind is null;
    exception when others then
    matricula:=null; nombre:=null;
    end;
    twbkwbis.P_OpenDoc('pkg_foto_demo.p_pagina1');
    htp.p('Bienvenido(a)');
    htp.p(matricula||' '||nombre);
    twbkwbis.P_DispInfo('pkg_foto_demo.p_pagina1.p_credencial');

    twbkfrmt.P_tableopen('DATADISPLAY', cattributes => 'align="CENTER" , border="1"' );
    twbkfrmt.P_tablerowopen;
/*
    get_enc_img_from_http (p_url  => 'http://www.icesi.edu.co/templates/existaya/images/logo.png',

                           p_clob => l_clob);
*/
    --010007697
    --get_enc_img_from_tab (p_image_id => 'joto', p_clob => l_clob);
     
    get_enc_img_from_fs(p_dir => 'IMAGEN',p_file=> matricula||'.jpg' ,p_clob => l_clob);
    if l_clob is not null then
    twbkfrmt.P_tabledata('<img src="data:image/jpg;base64, ' || l_clob || '" alt="Site Logo height="200" width="100"  " />',calign => 'center', ccolspan   => 4 );
    end if;
   -- twbkfrmt.P_tabledata('<img src="data:image/jpg;' || l_clob );
    --twbkfrmt.P_tabledata('<img src="http://contacto.utel.edu.mx/static/img/logo-utel.svg" height="500" width="20">');
    
    twbkfrmt.P_tablerowclose;
    --
    twbkfrmt.P_tableclose;
    twbkfrmt.P_tableopen('DATADISPLAY', cattributes => 'align="CENTER" , border="1"' );
    twbkfrmt.P_tablerowopen;
    twbkfrmt.P_tabledataheader('Programa');
    twbkfrmt.P_tabledataheader('Plan');
    twbkfrmt.P_tabledataheader('Estatus');
    twbkfrmt.P_tabledataheader('Periodo Ingreso');
    twbkfrmt.P_tabledataheader('Último Periodo Inscripción');
    twbkfrmt.P_tablerowclose;

    FOR stu_rec IN
     /* (SELECT spriden_id iden,
              spriden_last_name apellidos,
              spriden_first_name || ' ' || spriden_mi nombre,
              spbpers_sex genero
         FROM spriden
         LEFT JOIN spbpers on spbpers_pidm = spriden_pidm
        WHERE SPRIDEN_PIDM = l_pidm
          AND SPRIDEN_CHANGE_IND IS NULL
      )*/
      (SELECT distinct smrprle_program||'||'||smrprle_program_desc prog, stvstst_desc estatus, '20'||substr(sgbstdn_term_code_admit,3,2)||'-'||substr(sgbstdn_term_code_admit,6,1) Ingreso,
            case when substr(sgbstdn_term_code_ctlg_1,3,2) < '15' then '2011'
              when substr(sgbstdn_term_code_ctlg_1,3,2) >= '15' then '20'||substr(sgbstdn_term_code_ctlg_1,3,2)
       end plan,
      (select max( '20'||substr(sfrstcr_term_code,3,2)||'-'||substr(sfrstcr_term_code,6,1)) from sfrstcr, sobcurr, sorlcur
                                                                              where sgbstdn_pidm=sfrstcr_pidm
                                                                              and     sgbstdn_program_1=sobcurr_program 
                                                                              and     sobcurr_curr_rule=sorlcur_curr_rule
                                                                              and     sorlcur_pidm=sfrstcr_pidm
                                                                              and     sfrstcr_stsp_key_sequence=sorlcur_key_seqno) periodo
        from sgbstdn a, smrprle, stvstst
        where sgbstdn_pidm=l_pidm
        and    sgbstdn_program_1=smrprle_program
        and    stvstst_code=sgbstdn_stst_code
        and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn c
                                                         where a.sgbstdn_pidm=c.sgbstdn_pidm
                                                         and    a.sgbstdn_program_1=c.sgbstdn_program_1
                                                         and    a.sgbstdn_term_code_ctlg_1=c.sgbstdn_term_code_ctlg_1)
        order by ingreso)
        
    LOOP
      twbkfrmt.P_tablerowopen;
      twbkfrmt.P_tabledata(stu_rec.prog);
      twbkfrmt.P_tabledata(stu_rec.plan);
      twbkfrmt.P_tabledata(stu_rec.estatus);
      twbkfrmt.P_tabledata(stu_rec.ingreso);
      twbkfrmt.P_tabledata(stu_rec.periodo);
      twbkfrmt.P_tablerowclose;
      --
      twbkfrmt.P_tablerowopen;
      twbkfrmt.P_tablerowclose;
      --
    END LOOP;
    twbkfrmt.P_tableclose;
    twbkwbis.P_CloseDoc('8.5');
exception when others then
    twbkfrmt.P_tableopen('DATADISPLAY', cattributes => 'align="CENTER" , border="1"' );
    twbkfrmt.P_tablerowopen;
/*
    get_enc_img_from_http (p_url  => 'http://www.icesi.edu.co/templates/existaya/images/logo.png',

                           p_clob => l_clob);
*/
    --010007697
    --get_enc_img_from_tab (p_image_id => 'joto', p_clob => l_clob);
    l_clob:=null;
    get_enc_img_from_fs(p_dir => 'IMAGEN',p_file=> 'image-not-found.jpg' ,p_clob => l_clob);
    
    twbkfrmt.P_tabledata('<img src="data:image/jpg;base64, ' || l_clob || '" alt="Site Logo height="250" width="120"  " />',calign => 'center', ccolspan   => 4 );
   -- twbkfrmt.P_tabledata('<img src="data:image/jpg;' || l_clob );
    --twbkfrmt.P_tabledata('<img src="http://contacto.utel.edu.mx/static/img/logo-utel.svg" height="500" width="20">');
    
    twbkfrmt.P_tablerowclose;
    --
    twbkfrmt.P_tableclose;
   twbkfrmt.P_tableopen('DATADISPLAY', cattributes => 'align="CENTER" , border="1"' );
    twbkfrmt.P_tablerowopen;
    twbkfrmt.P_tabledataheader('Programa');
     twbkfrmt.P_tabledataheader('Plan');
    twbkfrmt.P_tabledataheader('Estatus');
    twbkfrmt.P_tabledataheader('Periodo Ingreso');
    twbkfrmt.P_tabledataheader('Último Periodo Inscripción');
     
    twbkfrmt.P_tablerowclose;

    FOR stu_rec IN
     /* (SELECT spriden_id iden,
              spriden_last_name apellidos,
              spriden_first_name || ' ' || spriden_mi nombre,
              spbpers_sex genero
         FROM spriden
         LEFT JOIN spbpers on spbpers_pidm = spriden_pidm
        WHERE SPRIDEN_PIDM = l_pidm
          AND SPRIDEN_CHANGE_IND IS NULL
      )*/
      (SELECT distinct smrprle_program||'||'||smrprle_program_desc prog, stvstst_desc estatus, '20'||substr(sgbstdn_term_code_admit,3,2)||'-'||substr(sgbstdn_term_code_admit,6,1) Ingreso,
            case when substr(sgbstdn_term_code_ctlg_1,3,2) < '15' then '2011'
              when substr(sgbstdn_term_code_ctlg_1,3,2) >= '15' then '20'||substr(sgbstdn_term_code_ctlg_1,3,2)
       end plan,
      (select max( '20'||substr(sfrstcr_term_code,3,2)||'-'||substr(sfrstcr_term_code,6,1)) from sfrstcr, sobcurr, sorlcur
                                                                              where sgbstdn_pidm=sfrstcr_pidm
                                                                              and     sgbstdn_program_1=sobcurr_program 
                                                                              and     sobcurr_curr_rule=sorlcur_curr_rule
                                                                              and     sorlcur_pidm=sfrstcr_pidm
                                                                              and     sfrstcr_stsp_key_sequence=sorlcur_key_seqno) periodo
        from sgbstdn a, smrprle, stvstst
        where sgbstdn_pidm=l_pidm
        and    sgbstdn_program_1=smrprle_program
        and    stvstst_code=sgbstdn_stst_code
        and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn c
                                                         where a.sgbstdn_pidm=c.sgbstdn_pidm
                                                         and    a.sgbstdn_program_1=c.sgbstdn_program_1
                                                         and    a.sgbstdn_term_code_ctlg_1=c.sgbstdn_term_code_ctlg_1)
        order by ingreso)
        
    LOOP
      twbkfrmt.P_tablerowopen;
      twbkfrmt.P_tabledata(stu_rec.prog);
      twbkfrmt.P_tabledata(stu_rec.plan);
      twbkfrmt.P_tabledata(stu_rec.estatus);
      twbkfrmt.P_tabledata(stu_rec.ingreso);
      twbkfrmt.P_tabledata(stu_rec.periodo);
      twbkfrmt.P_tablerowclose;
      --
      twbkfrmt.P_tablerowopen;
      twbkfrmt.P_tablerowclose;
      --
    END LOOP;
    twbkfrmt.P_tableclose;
    twbkwbis.P_CloseDoc('8.5');
END;
END;
/

DROP PUBLIC SYNONYM PKG_FOTO_DEMO;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FOTO_DEMO FOR BANINST1.PKG_FOTO_DEMO;


GRANT EXECUTE ON BANINST1.PKG_FOTO_DEMO TO PUBLIC;
