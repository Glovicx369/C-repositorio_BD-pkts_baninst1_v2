DROP PACKAGE BODY BANINST1.PKG_UTEL_OMA;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_utel_oma 
as 

procedure p_pagina1 is 
begin


    HTP.htmlopen;
    HTP.HEADOPEN;
    htp.title('Hola  Mundo Titulo');
    htp.comment('Esta es la seccion en HTML de encabezado');
    htp.headclose;
    
    htp.bodyopen(null, 'text="blue"');
    htp.p('yeah, you guessed it .... Hola Mundo');
     
    
    htp.bodyclose;
    HTP.HTMLCLOSE;
    
end p_pagina1;

PROCEDURE p_pagina2
  
  is
  
  BEGIN

     HTP.ULISTOPEN;
     HTP.LISTHEADER ('Listado de Niveles');
     
     For c in (select * from STVLEVL ) loop
     
      HTP.LISTITEM(c.STVLEVL_DESC);
      
     end loop;

HTP.ULISTCLOSE;

 END;

PROCEDURE p_pagina3
  
  is
  
  BEGIN
  
  htp.tableopen;
  htp.tablerowopen;
  htp.tableheader('ID Estudiante');
  htp.tableheader('Apellidos');
  htp.tableheader('Nombres');
  htp.tablerowclose;
  
  for my_rec in (select spriden_id iden,spriden_last_name apellidos,spriden_first_name||' '||spriden_mi nombre from spriden) loop
       htp.tablerowopen;
       
      -- ERROR htp.tabledata(htp.anchor('#', my_rec.iden, '', ''));

       htp.tabledata( htf.anchor('/fotos/' || my_rec.iden || '.jpg', my_rec.iden, CATTRIBUTES => 'target="_blank"') );
       
--       htp.p('<td>');
--       htp.anchor('#', my_rec.iden);
--       htp.p('</td>');

       htp.tabledata(my_rec.apellidos);
       htp.tabledata(my_rec.nombre);
       htp.tablerowclose;
  end loop;
  
  htp.tableclose;
  
  end;

PROCEDURE p_pagina4
  
  is
  
  BEGIN
  
  HTP.FORMOPEN('pkg_utel_oma.p_pagina5', 'GET');

htp.p('Busqueda ID:');
htp.formtext ('v_cuenta');
htp.br;
htp.formsubmit ('', 'Enviar');

HTP.FORMCLOSE;
  
  end;

PROCEDURE p_pagina5(v_cuenta varchar2 default null)
  
  is
  
  BEGIN
  
  htp.tableopen;
  htp.tablerowopen;
  htp.tableheader('ID Estudiante');
  htp.tableheader('Apellidos');
  htp.tableheader('Nombres');
  htp.tablerowclose;
  
  for my_rec in (select spriden_id iden,spriden_last_name apellidos,spriden_first_name||' '||spriden_mi nombre from spriden
                      WHERE SPRIDEN_ID like '%' || v_cuenta || '%'
                   And SPRIDEN_CHANGE_IND is null)  loop
      htp.tablerowopen;
       
      -- ERROR htp.tabledata(htp.anchor('#', my_rec.iden, '', ''));

       htp.tabledata( htf.anchor('/fotos/' || my_rec.iden || '.jpg', my_rec.iden, CATTRIBUTES => 'target="_blank"') );
       
--       htp.p('<td>');
--       htp.anchor('#', my_rec.iden);
--       htp.p('</td>');

       htp.tabledata(my_rec.apellidos);
       htp.tabledata(my_rec.nombre);
       htp.tablerowclose;
  end loop;
  
  htp.tableclose;
  
  end;

PROCEDURE p_pagina6
  
  is
  pidm number; -- DEFINE FOR OUTPUT
  BEGIN
  if not twbkwbis.F_ValidUser(pidm) then return; end if;

     twbkwbis.P_OpenDoc('pkg_utel_oma.p_pagina6');

     twbkwbis.P_DispInfo('pkg_utel_oma.p_pagina6');

     HTP.FORMOPEN('pkg_utel_oma.p_pagina13', 'GET');

htp.p('Busqueda ID:');
htp.formtext ('v_cuenta');
htp.br;
htp.formsubmit ('', 'Enviar');

HTP.FORMCLOSE;
twbkwbis.P_CloseDoc('8.7.1');  
  end;

PROCEDURE p_pagina7(v_cuenta varchar2 default null)
  
  is
  pidm number; -- DEFINE FOR OUTPUT  
  BEGIN

  if not twbkwbis.F_ValidUser(pidm) then return; end if;

     twbkwbis.P_OpenDoc('pkg_utel_oma.p_pagina7');

     twbkwbis.P_DispInfo('pkg_utel_oma.p_pagina7');

  --htp.tableopen;
  twbkfrmt.P_tableopen('DATADISPLAY');
  twbkfrmt.P_tablerowopen;
  --htp.tablerowopen;
  --htp.tableheader('ID Estudiante');
  --htp.tableheader('Apellidos');
  --htp.tableheader('Nombres');
  twbkfrmt.P_tabledataheader('ID Estudiante');
  twbkfrmt.P_tabledataheader('Apellidos');
  twbkfrmt.P_tabledataheader('Nombres');
 -- htp.tablerowclose;
   twbkfrmt.P_tablerowclose;
  for my_rec in (select spriden_id iden,spriden_last_name apellidos,spriden_first_name||' '||spriden_mi nombre from spriden
                      WHERE SPRIDEN_ID like '%' || v_cuenta || '%'
                   And SPRIDEN_CHANGE_IND is null)  loop
      --htp.tablerowopen;
  twbkfrmt.P_tablerowopen('DATADISPLAY');     
      -- ERROR htp.tabledata(htp.anchor('#', my_rec.iden, '', ''));
       twbkfrmt.P_tabledata(twbkfrmt.F_PrintAnchor('/fotos/' || my_rec.iden || '.jpg', my_rec.iden, CATTRIBUTES => 'target="_blank"') );
       --htp.tabledata( htf.anchor('/fotos/' || my_rec.iden || '.jpg', my_rec.iden, CATTRIBUTES => 'target="_blank"') );
       
--       htp.p('<td>');
--       htp.anchor('#', my_rec.iden);
--       htp.p('</td>');

       --htp.tabledata(my_rec.apellidos);
       --htp.tabledata(my_rec.nombre);
       --htp.tablerowclose;
       twbkfrmt.P_tabledata(my_rec.apellidos);
       twbkfrmt.P_tabledata(my_rec.nombre);
       twbkfrmt.P_tablerowclose;
  end loop;
  
  --htp.tableclose;
  twbkfrmt.P_tableclose;
  twbkwbis.P_CloseDoc('8.7.1');
  end;

PROCEDURE p_pagina8
  
  is
  pidm number; -- DEFINE FOR OUTPUT
  BEGIN
  if not twbkwbis.F_ValidUser(pidm) then return; end if;

     twbkwbis.P_OpenDoc('pkg_utel_oma.p_pagina6');

     twbkwbis.P_DispInfo('pkg_utel_oma.p_pagina6');

     HTP.FORMOPEN('pkg_utel_oma.p_pagina9', 'GET');

htp.p('ID Estudiante:');
htp.formtext ('v_cuenta');
htp.br;
htp.p('Nombre:');
htp.formtext ('v_nombre');
htp.br;
htp.formsubmit ('', 'Enviar');

HTP.FORMCLOSE;
twbkwbis.P_CloseDoc('8.7.1');  
  end;

PROCEDURE p_pagina9(v_cuenta varchar2 default null, v_nombre varchar2 default null)
  
  is
  pidm number; -- DEFINE FOR OUTPUT  
  BEGIN

  if not twbkwbis.F_ValidUser(pidm) then return; end if;

     twbkwbis.P_OpenDoc('pkg_utel_oma.p_pagina9');

     twbkwbis.P_DispInfo('pkg_utel_oma.p_pagina9');

htp.p ('ID:'||v_cuenta);
htp.br;
htp.p ('Nombre:'||v_nombre);

twbkfrmt.P_PrintAnchor(twbkwbis.f_cgibin  || 'pkg_utel_oma.p_pagina10' ||

      '?v_cuenta=' || '99999' ||

      '&v_nombre=' || 'Forma 2',

      ctext=>'LLamada en metodo GET');

  
  twbkwbis.P_CloseDoc('8.7.1');
  end;

PROCEDURE p_pagina10(v_cuenta varchar2 default null, v_nombre varchar2 default null)
  
  is
  pidm number; -- DEFINE FOR OUTPUT  
  BEGIN

  if not twbkwbis.F_ValidUser(pidm) then return; end if;

     twbkwbis.P_OpenDoc('pkg_utel_oma.p_pagina10');

     twbkwbis.P_DispInfo('pkg_utel_oma.p_pagina10');

htp.p ('ID:'||v_cuenta);
htp.br;
htp.p ('Nombre:'||v_nombre);
 -- Version 3

     -- pasando valores ocultos

     HTP.FORMOPEN('pkg_utel_oma.p_pagina11', 'POST');

      htp.formHidden ('v_cuenta', '93102416');

      htp.formHidden ('v_nombre', 'Forma 3');
      htp.br;
      htp.formsubmit ('', 'Enviar 2');
  twbkwbis.P_CloseDoc('8.7.1');
  end;

PROCEDURE p_pagina11(v_cuenta varchar2 default null, v_nombre varchar2 default null)
  
  is
  pidm number; -- DEFINE FOR OUTPUT  
  BEGIN

  if not twbkwbis.F_ValidUser(pidm) then return; end if;

     twbkwbis.P_OpenDoc('pkg_utel_oma.p_pagina11');

     twbkwbis.P_DispInfo('pkg_utel_oma.p_pagina11');

    
htp.p ('ID:'||v_cuenta);
htp.br;
htp.p ('Nombre:'||v_nombre);
 
 -- Version 4

    -- pasando valores por parametros de sesion

     HTP.FORMOPEN('pkg_utel_oma.p_pagina12', 'POST');

      twbkwbis.p_setparam (pidm, 'v_cuenta', '210392871');

      twbkwbis.p_setparam (pidm, 'v_nombre', 'Forma 4');

      htp.formsubmit ('', 'Enviar 3');

 

      HTP.FORMCLOSE;

      
      HTP.FORMCLOSE;


  twbkwbis.P_CloseDoc('8.7.1');
  end;

PROCEDURE p_pagina12(v_cuenta varchar2 default null, v_nombre varchar2 default null)
  
  is
  pidm number; -- DEFINE FOR OUTPUT  
  BEGIN

  if not twbkwbis.F_ValidUser(pidm) then return; end if;

     twbkwbis.P_OpenDoc('pkg_utel_oma.p_pagina12');

     twbkwbis.P_DispInfo('pkg_utel_oma.p_pagina12');

   if (v_cuenta is NULL) then

        twbkfrmt.P_tabledata( twbkwbis.f_getparam (pidm, 'v_cuenta') );

    else

      HTP.TABLEDATA(v_cuenta);

    end if;

    if (v_nombre is NULL) then

        twbkfrmt.P_tabledata( twbkwbis.f_getparam (pidm, 'v_nombre') );

    else

      HTP.TABLEDATA(v_nombre);

    end if;

htp.p ('ID:'||v_cuenta);
htp.br;
htp.p ('Nombre:'||v_nombre);
 
 
      
      HTP.FORMCLOSE;


  twbkwbis.P_CloseDoc('8.7.1');
  end;

PROCEDURE p_pagina13(v_cuenta varchar2 default null, err_mess varchar2 default null)
  
  is
  pidm number; -- DEFINE FOR OUTPUT
  fecha_nac  varchar2(12);
  civil           varchar2(1);
  sexo         varchar2(1);
  lv_chk_fem   varchar2(20);      
  lv_chk_masc   varchar2(20);      
  lv_chk_nodef   varchar2(20);      

  BEGIN
  if not twbkwbis.F_ValidUser(pidm) then return; end if;

     twbkwbis.P_OpenDoc('pkg_utel_oma.p_pagina13');

     twbkwbis.P_DispInfo('pkg_utel_oma.p_pagina13');

     --HTP.FORMOPEN('pkg_utel_oma.p_pagina7', 'GET');


SELECT SPBPERS_PIDM, SPBPERS_BIRTH_DATE, SPBPERS_MRTL_CODE, SPBPERS_SEX 
into  pidm, fecha_nac, civil, sexo
FROM SPBPERS 
WHERE SPBPERS_PIDM in (select spriden_pidm from spriden
                                        where spriden_change_ind is null
                                        and     spriden_id= v_cuenta);

HTP.FORMOPEN('pkg_utel_oma.p_pagina14', 'GET');

htp.p('Cuenta:');
htp.formtext ('v_cuenta','','',v_cuenta,'');
htp.br;
htp.p('Fecha Nacimiento:');
htp.formtext ('Fecha_nac','','',fecha_nac,'');
htp.br;
htp.p('Estado Civil:');
--htp.formtext ('Estado civil','','',civil,'');
htp.formselectopen('Civil');
for c in (select stvmrtl_code, stvmrtl_desc from stvmrtl) loop
--htp.formselectoption(c.stvmrtl_code||' '||c.stvmrtl_desc);
    if ( c.stvmrtl_code = civil ) then
       htp.p ('<option value="' || c.stvmrtl_code || '" SELECTED>' ||
               c.stvmrtl_desc || '</option>');
    else           
       htp.p ('<option value="' || c.stvmrtl_code || '">' ||
               c.stvmrtl_desc || '</option>');
    end if;
end loop;
HTP.FORMSELECTCLOSE;
htp.br;
htp.p('Sexo:');

  if (sexo = 'F') then      lv_chk_fem := 'CHECKED';  else       lv_chk_fem := '';   end if;      
  if (sexo = 'M') then      lv_chk_masc := 'CHECKED';  else      lv_chk_masc := '';   end if;      
  if (sexo = 'N') then      lv_chk_nodef := 'CHECKED';  else     lv_chk_nodef := '';   end if;
  
   HTP.P ( 'FEMENINO' || htf.formradio ('Sexo', 'F', lv_chk_fem)     ||
            'MASCULINO' || htf.formradio ('Sexo', 'M', lv_chk_masc)     ||
             'NO DEFINIDO' || htf.formradio ('Sexo', 'N', lv_chk_nodef)   ); 
--htp.formtext ('Sexo','','',sexo,'');
htp.br;

 htp.formsubmit ('', 'Enviar 3');
 
      if err_mess is not null then
        htp.br;
        twbkfrmt.p_printmessage(err_mess,'NOTE');
        --htp.p(err_mess);
        htp.br;
     end if;

HTP.FORMCLOSE;
twbkwbis.P_CloseDoc('8.7.1');  
  end;

procedure p_pagina14(v_cuenta varchar2, Fecha_nac Varchar2 Default null, Civil Varchar2 Default null, Sexo Varchar2 Default null)
is

  pidm number; -- DEFINE FOR OUTPUT  
  lv_fecha date;
  lv_count number;
  lv_error varchar2(50);
  g_date_mask  varchar2(20) := 'DD/MM/YYYY';
  lv_rowid number;


begin

  if not twbkwbis.F_ValidUser(pidm) then return; end if;
  -- VALIDA PARAMETROS
  lv_error := ''; 

  if (v_cuenta is null) then
    lv_error := lv_error || 'No se recibio el id' || htf.br;
  end if;  

  if (Fecha_nac is null) then
    lv_error := lv_error || 'No se recibio la Fecha Nac' || htf.br;
  end if;  

  if (civil is null) then
    lv_error := lv_error || 'No se recibio el Edo Civil' || htf.br;
  end if;  

  if (sexo is null) then
    lv_error := lv_error || 'No se recibio el Genero' || htf.br;
  end if;  

-- VALIDAR TIPO DE DATOS

-- valida fecha

begin
  lv_fecha := to_date (Fecha_nac, g_date_mask);
exception
  when others then
    lv_error := lv_error || 'Fecha erronea' || htf.br;  
end;

    if lv_error is not null then
       pkg_utel_oma.p_pagina13(v_cuenta, lv_error);
       return;
    end if;

select spriden_pidm into pidm from spriden
where spriden_id=v_cuenta
and    spriden_change_ind is null;

 select count(1) into lv_count from SPBPERS WHERE SPBPERS_PIDM = pidm ;
   if (lv_count = 1) then
     GB_BIO.p_update (
                       P_PIDM         => pidm         ,
                       P_BIRTH_DATE   => lv_fecha    ,
                       P_MRTL_CODE    => civil ,
                       P_SEX          => sexo
                       );
                       lv_error:=( 'Registro Modificado');
   else   
     GB_BIO.p_create (
                       P_PIDM         => pidm         ,
                       P_BIRTH_DATE   => fecha_nac    ,
                       P_MRTL_CODE    => civil ,
                       P_SEX          => sexo       ,
                       P_ROWID_OUT    => lv_rowid
                       );
                        lv_error:= 'Registro Insertado';
   end if;
     
       pkg_utel_oma.p_pagina13(v_cuenta, lv_error);
       return;
       
       gb_common.p_commit;

end;

end pkg_utel_oma;
/

DROP PUBLIC SYNONYM PKG_UTEL_OMA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_UTEL_OMA FOR BANINST1.PKG_UTEL_OMA;


GRANT EXECUTE ON BANINST1.PKG_UTEL_OMA TO PUBLIC;
