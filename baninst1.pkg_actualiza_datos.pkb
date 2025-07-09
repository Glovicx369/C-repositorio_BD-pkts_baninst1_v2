DROP PACKAGE BODY BANINST1.PKG_ACTUALIZA_DATOS;

CREATE OR REPLACE PACKAGE BODY BANINST1."PKG_ACTUALIZA_DATOS" AS
FUNCTION f_actualiza_dato_grlas(p_nombre in varchar2, 
 p_apellido in varchar2, 
 p_fechaNac in date, 
 p_genero in varchar2, 
 p_telefono in varchar2, 
 p_email in varchar2, 
 p_celular in varchar2, 
 p_nacional in varchar2, 
 p_pidm in number, 
 p_movil in varchar2, 
 p_area in varchar2, 
 p_edo_civ in varchar2,
 p_pais_na   varchar2,
 p_estado_na varchar2,
 p_ciudad_na varchar2,
 p_ciudad_d_na varchar2
 ) return varchar2

IS 
 l_nombre varchar(100);
 l_apellido varchar(100);
 l_fechaNac date;
 l_genero varchar(100);
 l_telefono varchar(100);
 l_celular varchar(100);
 l_nacional varchar(100);
 l_email varchar(100);
 l_pais_na    varchar(100);
 l_estado_na    varchar(100);
 l_ciudad_na    varchar(100);
 l_ciudad_d_na    varchar(100);
 l_contar_sp number;
 l_retorna varchar2(200):='Exito';
 l_contar number;
 l_contar_r number;
 l_contar_m number;
 l_contar_n     number; 
 l_secuencia number :=0;
 l_spriden_id varchar2(100);
 l_nomact number:=0;
 l_apeact number:=0;
 l_fnacact number:=0;
 l_gencact number:=0;
 l_nacact number:=0;
 l_ecivact number:=0;

begin

 if p_nombre is not null then
 
 Begin 
 select count(1)
 into l_nomact
 from spriden
 WHERE SPRIDEN_PIDM = p_pidm
 AND SPRIDEN_CHANGE_IND is null
 And SPRIDEN_FIRST_NAME = p_nombre;
 Exception
 when others then 
 l_nombre :=0;
 End;
 
 If l_nomact = 0 then 
 
 Begin
 UPDATE SPRIDEN
 SET SPRIDEN_FIRST_NAME = p_nombre,
 SPRIDEN_ACTIVITY_DATE = SYSDATE
 WHERE SPRIDEN_PIDM = p_pidm
 AND SPRIDEN_CHANGE_IND is null;
 COMMIT; 
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna :=' Error al actualizar Nombre' || SQLERRM ;
 End;
 
 
 Begin
 UPDATE SPBPERS
 SET SPBPERS_LEGAL_NAME = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(UPPER(p_apellido||' '||p_nombre),'Á','A'),'É','E'),'Í','I'),'Ó','O'),'Ú','U'),'Ñ','N'),'/',' ')
 WHERE SPBPERS_PIDM = p_pidm;
 COMMIT; 
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna :=' Error al actualizar Nombre_legal' || SQLERRM ;
 End;
 
 l_spriden_id:= null;

 begin
 select spriden_id
 into l_spriden_id
 from spriden
 where 1 = 1
 and spriden_change_ind is null
 and spriden_pidm = p_pidm;
 
 exception when others then
 l_spriden_id:= null;
 end;
 
 
-- BEGIN
-- 
-- INSERT INTO SZTBIMA( 
-- sztbima_first_name,
-- sztbima_last_name,
-- sztbima_proceso, 
-- sztbima_estatus, 
-- sztbima_observaciones, 
-- sztbima_pidm,
-- sztbima_id,
-- sztbima_email_address,
-- sztbima_birth_date,
-- sztbima_sex,
-- sztbima_status_ind,
-- sztbima_usuario_actualiza, 
-- sztbima_fecha_actualiza
-- )
-- VALUES
-- (
-- p_nombre,
-- null,
-- 'SPRIDEN', 
-- null,
-- null, 
-- p_pidm , 
-- l_spriden_id,
-- null,
-- null,
-- null,
-- '7',
-- USER,
-- SYSDATE
-- );
-- EXCEPTION
-- WHEN OTHERS THEN 
-- l_retorna:=('Error al insertar nombre en bitacora'||sqlerrm);
-- END;
-- 
 End if;

 
 end if ;
 
 if p_apellido is not null then
 
 Begin
 select count(1)
 into l_apeact
 from spriden
 WHERE SPRIDEN_PIDM = p_pidm
 AND SPRIDEN_CHANGE_IND is null
 And SPRIDEN_LAST_NAME = p_apellido;
 Exception
 when others then 
 l_apellido :=0;
 End;
 
 If l_apeact = 0 then 
 
 Begin
 UPDATE SPRIDEN
 SET SPRIDEN_LAST_NAME = p_apellido,
 SPRIDEN_ACTIVITY_DATE = SYSDATE
 WHERE SPRIDEN_PIDM = p_pidm
 AND SPRIDEN_CHANGE_IND is null;
 commit; 
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna :=' Error al actualizar Apellido' || SQLERRM ;
 End;
 
 Begin
 UPDATE SPBPERS
 SET SPBPERS_LEGAL_NAME = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(UPPER(p_apellido||' '||p_nombre),'Á','A'),'É','E'),'Í','I'),'Ó','O'),'Ú','U'),'Ñ','N'),'/',' ')
 WHERE SPBPERS_PIDM = p_pidm;
 COMMIT; 
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna :=' Error al actualizar Nombre_legal' || SQLERRM ;
 End;
 
 l_spriden_id:= null;

 begin
 select spriden_id
 into l_spriden_id
 from spriden
 where 1 = 1
 and spriden_change_ind is null
 and spriden_pidm = p_pidm;
 
 exception when others then
 l_spriden_id:= null;
 end;
 
 
-- BEGIN
-- 
-- INSERT INTO SZTBIMA( 
-- sztbima_first_name,
-- sztbima_last_name,
-- sztbima_proceso, 
-- sztbima_estatus, 
-- sztbima_observaciones, 
-- sztbima_pidm,
-- sztbima_id,
-- sztbima_email_address,
-- sztbima_birth_date,
-- sztbima_sex,
-- sztbima_status_ind,
-- sztbima_usuario_actualiza, 
-- sztbima_fecha_actualiza
-- )
-- VALUES
-- (
-- null,
-- p_apellido,
-- 'SPRIDEN', 
-- null,
-- null, 
-- p_pidm , 
-- l_spriden_id,
-- null,
-- null,
-- null,
-- '7',
-- USER,
-- SYSDATE
-- );
-- EXCEPTION
-- WHEN OTHERS THEN 
-- l_retorna:=('Error al insertar apellido en bitacora'||sqlerrm);
-- END;
 
 End if;
 
 end if;
 
 if p_fechaNac is not null then
 
 Begin 
 select count(1)
 into l_fnacact
 from SPBPERS
 WHERE SPBPERS_PIDM = p_pidm
 And SPBPERS_BIRTH_DATE = p_fechaNac;
 Exception
 when others then 
 l_fnacact :=0;
 End;
 
 If l_fnacact = 0 then
 
 Begin
 UPDATE SPBPERS
 SET SPBPERS_BIRTH_DATE = p_fechaNac
 WHERE SPBPERS_PIDM = p_pidm;
 commit; 
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna :=' Error al actualizar Fecha_Nacimiento' || SQLERRM ;
 End;
 
 l_spriden_id:= null;

 begin
 select spriden_id
 into l_spriden_id
 from spriden
 where 1 = 1
 and spriden_change_ind is null
 and spriden_pidm = p_pidm;
 
 exception when others then
 l_spriden_id:= null;
 end;
 
 
-- BEGIN
-- 
-- INSERT INTO SZTBIMA( 
-- sztbima_first_name,
-- sztbima_last_name,
-- sztbima_proceso, 
-- sztbima_estatus, 
-- sztbima_observaciones, 
-- sztbima_pidm,
-- sztbima_id,
-- sztbima_email_address,
-- sztbima_birth_date,
-- sztbima_sex,
-- sztbima_status_ind,
-- sztbima_usuario_actualiza, 
-- sztbima_fecha_actualiza
-- )
-- VALUES
-- (
-- null,
-- null,
-- 'SPRIDEN', 
-- null,
-- null, 
-- p_pidm , 
-- l_spriden_id,
-- null,
-- p_fechaNac,
-- null,
-- null,
-- USER,
-- SYSDATE
-- );
-- EXCEPTION
-- WHEN OTHERS THEN 
-- l_retorna:=('Error al insertar fecha nacimiento en bitacora'||sqlerrm);
-- END;
 
 End if; 
 
 end if;
 
 
 if p_genero is not null then
 
 Begin 
 select count(1)
 into l_gencact
 from SPBPERS
 WHERE SPBPERS_PIDM = p_pidm
 And SPBPERS_SEX = p_genero;
 Exception
 when others then 
 l_genero :=0;
 End;
 
 If l_gencact = 0 then
 
 Begin
 UPDATE SPBPERS
 SET SPBPERS_SEX = p_genero
 WHERE SPBPERS_PIDM = p_pidm;
 commit; 
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna :=' Error al actualizar Genero' || SQLERRM ;
 End;
 End if;
 
 end if;
 
 
 IF p_telefono IS NOT NULL THEN
 --AND p_area IS NOT NULL THEN  --GABY
 
 
 
 BEGIN
 SELECT COUNT(SPRTELE_PIDM)
 INTO l_contar_r
 FROM SPRTELE
 WHERE 1=1
 --AND SPRTELE_PHONE_NUMBER = p_telefono
 AND SPRTELE_PIDM = p_pidm
 AND SPRTELE_TELE_CODE = 'RESI'
 ANd SPRTELE_PRIMARY_IND ='Y';
 
 IF l_contar_r = 0 THEN

    Begin 
         INSERT INTO SPRTELE 
         VALUES (p_pidm,
         l_secuencia,
         'RESI',
         SYSDATE,
         NULL,--p_area, GABY
         p_area || p_telefono,
         null,
         null,
         null,
         null,
         'Y',
         null,
         null,
         null,
         null,
         null,
         null,
         null,
         null,
         null
         );
    Exception
            When Others then 
                null;
    End; 
 commit; 
 END IF; 

 
 IF l_contar_r > 0 THEN 
 
    Begin 
         select NVL (MAX (SPRTELE_SEQNO), 0) + 1
         INTO l_secuencia
         FROM SPRTELE
         WHERE SPRTELE_PIDM = p_pidm
         AND SPRTELE_TELE_CODE = 'RESI';
    Exception
        When Others then 
         l_secuencia:=1;
    End;
 
    Begin
         UPDATE SPRTELE
         SET SPRTELE_PRIMARY_IND = 'N',
         SPRTELE_ACTIVITY_DATE = SYSDATE
         WHERE SPRTELE_PIDM = p_pidm
         AND SPRTELE_TELE_CODE = 'RESI'
         And SPRTELE_PRIMARY_IND ='Y';
    Exception
        When Others then 
            null;
    End;

    Begin
    
         INSERT INTO SPRTELE 
         VALUES (p_pidm,
         l_secuencia,
         'RESI',
         SYSDATE,
         NULL,--p_area,GABY 
         p_area||p_telefono,
         null,
         null,
         null,
         null,
         'Y',
         null,
         null,
         null,
         null,
         null,
         null,
         null,
         null,
         null
         );     
    
    Exception
        When Others then 
            null;
    End;

 
 END IF; 
 COMMIT; 
 END; 
 END IF;
 
 
 IF p_celular IS NOT NULL THEN 
 --AND p_movil IS NOT NULL THEN GABY
 
 BEGIN
 SELECT COUNT(SPRTELE_PIDM)
 INTO l_contar_m
 FROM SPRTELE
 WHERE 1=1
 --AND SPRTELE_PHONE_NUMBER = p_telefono
 AND SPRTELE_PIDM = p_pidm
 AND SPRTELE_TELE_CODE = 'CELU';
 
 IF l_contar_m = 0 THEN
 
 begin
 select NVL (MAX (SPRTELE_SEQNO), 0) + 1
 INTO l_secuencia
 FROM SPRTELE
 WHERE SPRTELE_PIDM = p_pidm;
 --AND SPRTELE_TELE_CODE = 'RESI';
 end;
 
 

 INSERT INTO SPRTELE 
 VALUES (p_pidm,
 l_secuencia,
 'CELU',
 SYSDATE,
 NULL,--p_movil, GABY
 p_movil ||p_celular,
 null,
 null,
 null,
 null,
 'Y',
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 null
 ); 
 commit; 
 END IF; 

 
 IF l_contar_m > 0 THEN
 
 
 select NVL (MAX (SPRTELE_SEQNO), 0) + 1
 INTO l_secuencia
 FROM SPRTELE
 WHERE SPRTELE_PIDM = p_pidm; 
 
 UPDATE SPRTELE
 SET SPRTELE_PHONE_AREA = p_movil,
 SPRTELE_PHONE_NUMBER = p_movil||p_celular, --p_celular
 SPRTELE_ACTIVITY_DATE = SYSDATE
 WHERE SPRTELE_PIDM = p_pidm
 AND SPRTELE_TELE_CODE = 'CELU'
-- AND SPRTELE_SEQNO = l_secuencia -- fer 13/01
 ;
 commit; 
 END IF; 
 COMMIT; 
 END; 
 END IF;
 
 
 
 if p_nacional is not null then
 
 Begin 
 select count(1)
 into l_nacact
 from SPBPERS
 WHERE SPBPERS_PIDM = p_pidm
 And SPBPERS_CITZ_CODE = p_nacional;
 Exception
 when others then 
 l_nacional :=0;
 End;
 
 If l_nacact = 0 then
 
 Begin
 UPDATE SPBPERS
 SET SPBPERS_CITZ_CODE = p_nacional
 WHERE SPBPERS_PIDM = p_pidm;
 commit; 
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna :=' Error al actualizar Nacionalidad' || SQLERRM ;
 End;
 
 End if;
 
 end if;
 
if p_email is not null then 
 
 l_contar:=0; 
 
 BEGIN 
 /*
 SELECT COUNT(1) INTO l_contar
 FROM GOREMAL
 WHERE GOREMAL_EMAIL_ADDRESS = p_email
 and GOREMAL_PIDM != p_pidm;
-- AND GOREMAL_EMAL_CODE = 'PRIN'*/

    SELECT COUNT(1) INTO l_contar
      FROM GOREMAL a, GORADID b
     WHERE     a.GOREMAL_PIDM = b.GORADID_PIDM
           AND a.GOREMAL_EMAIL_ADDRESS = p_email
           AND b.GORADID_ADID_CODE = 'CAMP'
           AND a.GOREMAL_PIDM != p_pidm
           AND  NOT EXISTS
                      (SELECT COUNT (1)
                         FROM GORADID f
                        WHERE     f.GORADID_ADID_CODE = 'CAMP'
                              AND f.GORADID_PIDM = a.GOREMAL_PIDM
                              AND f.GORADID_ADDITIONAL_ID =
                                     b.GORADID_ADDITIONAL_ID);

 EXCEPTION
 WHEN OTHERS THEN
 l_retorna:=0;
 END; 
 DBMS_OUTPUT.PUT_LINE('Contar '||l_contar);
 
 IF l_contar > 0 THEN
 l_retorna :='Correo ya existente';
 
 DBMS_OUTPUT.PUT_LINE('Valor_1 '||l_retorna);
 
 Else
 
 DBMS_OUTPUT.PUT_LINE('Valor_2'||l_retorna);
 
 l_contar:=0; 
 
 BEGIN 
 SELECT COUNT(1) 
 INTO l_contar
 FROM GOREMAL
 WHERE GOREMAL_EMAIL_ADDRESS = p_email
 and GOREMAL_PIDM = p_pidm
 AND GOREMAL_EMAL_CODE = 'PRIN'
 ;
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna:=0;
 END; 
 
 If l_contar = 0 then 
 
 Begin 
 UPDATE GOREMAL
 SET GOREMAL_STATUS_IND = 'I',
 GOREMAL_PREFERRED_IND = 'N',
 GOREMAL_ACTIVITY_DATE = SYSDATE
 WHERE GOREMAL_PIDM = p_pidm
 AND GOREMAL_EMAL_CODE = 'PRIN';
 -- commit;
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna :=' Error al actualizar correo alterno' || SQLERRM ;
 End;
 
 
 Begin 
 INSERT INTO GOREMAL 
 VALUES (p_pidm,
 'PRIN',
 p_email,
 'A',
 'Y',
 SYSDATE,
 USER,
 null,
 'Y',
 'UTEL',
 null,
 null,
 null 
 ); 
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna :=' Error al insertar correo' || SQLERRM ; 
 
 End;
 
 l_spriden_id:= null;

 begin
 select spriden_id
 into l_spriden_id
 from spriden
 where 1 = 1
 and spriden_change_ind is null
 and spriden_pidm = p_pidm;
 
 exception when others then
 l_spriden_id:= null;
 end;
 
 
-- BEGIN
-- 
-- INSERT INTO SZTBIMA( 
-- sztbima_first_name,
-- sztbima_last_name,
-- sztbima_proceso, 
-- sztbima_estatus, 
-- sztbima_observaciones, 
-- sztbima_pidm,
-- sztbima_id,
-- sztbima_email_address,
-- sztbima_birth_date,
-- sztbima_sex,
-- sztbima_status_ind,
-- sztbima_usuario_actualiza, 
-- sztbima_fecha_actualiza
-- )
-- VALUES
-- (
-- null,
-- null,
-- 'GOREMAL', 
-- null,
-- null, 
-- p_pidm , 
-- l_spriden_id,
-- p_email,
-- null,
-- null,
-- '7',
-- USER,
-- SYSDATE
-- );
-- EXCEPTION
-- WHEN OTHERS THEN 
-- l_retorna:=('Error al insertar correo en bitacora'||sqlerrm);
-- END;
 
 End if; 
 
 
 COMMIT;
 
 
 End If;
 
End if;
 
 
 if p_edo_civ is not null then
 
 Begin 
 select count(1)
 into l_ecivact
 from SPBPERS
 WHERE SPBPERS_PIDM = p_pidm
 And SPBPERS_MRTL_CODE = p_edo_civ;
 Exception
 when others then 
 l_ecivact :=0;
 End;
 
 If l_ecivact = 0 then
 
 Begin
 UPDATE SPBPERS
 SET SPBPERS_MRTL_CODE = p_edo_civ
 WHERE SPBPERS_PIDM = p_pidm;
 commit; 
 EXCEPTION
 WHEN OTHERS THEN
 l_retorna :=' Error al actualizar Estado civil' || SQLERRM ;
 End;
 
 End if;
 
 end if;
 
 
     if p_pais_na is not null and p_estado_na  is not null and p_ciudad_na is not null and p_ciudad_d_na is not null then
      
      begin
       select count(SPRADDR_PIDM)
       into l_contar_n
        from SPRADDR
        where 1=1
        and SPRADDR_PIDM =  p_pidm
        and SPRADDR_ATYP_CODE = 'NA';
        
        if l_contar_n  = 0 then

                     insert into SPRADDR 
                        values (p_pidm,
                                       'NA',
                                       l_secuencia,
                                       null,
                                       null,
                                       null,
                                       null,
                                       null,
                                       p_ciudad_d_na,
                                       p_estado_na,
                                       null,
                                       p_ciudad_na,
                                       p_pais_na,
                                       null,
                                       null,
                                       null,
                                       null,
                                       SYSDATE,
                                       USER,
                                       null,
                                       null,
                                       null,
                                       null,
                                       null,
                                       null,
                                       null,
                                       'UTEL',
                                       null,
                                       null,
                                       null,
                                       null,
                                       null,
                                       USER,
                                       null
                                     );              
                                      commit;                    
            end if;  

        
            if l_contar_n  > 0 then
            
                
                select NVL (MAX (SPRADDR_SEQNO), 0) + 1
                into l_secuencia
                from SPRADDR
                where  SPRADDR_PIDM = p_pidm
                and SPRADDR_ATYP_CODE = 'NA';
            
                update SPRADDR
                     set SPRADDR_NATN_CODE = p_pais_na,
                     SPRADDR_STAT_CODE = p_estado_na,
                     SPRADDR_CNTY_CODE = p_ciudad_na,
                     SPRADDR_CITY = p_ciudad_d_na
                     where SPRADDR_PIDM = p_pidm
                     and SPRADDR_ATYP_CODE = 'NA'
                     and SPRADDR_SEQNO = l_secuencia;
                 commit;                                                                              
            END IF;    
           COMMIT;    
        END; 
   END IF;
    
 
 If l_retorna = 'Exito' then
 commit;
 else Rollback;
 End if;
 
 return (l_retorna);

end;

FUNCTION f_actualiza_domicilio(p_pidm in number, p_direccion_re in varchar2, p_colonia_re in varchar2, p_ciudad_re in varchar2, p_estado_re in varchar2, p_cp_re in varchar2, p_direccion_co in varchar2,
 p_colonia_co in varchar2, p_ciudad_co in varchar2, p_estado_co in varchar2, p_cp_co in varchar2, p_pais_co in varchar2, p_municipio_co in varchar2, p_bandera_dom in varchar2)return varchar2
 
is 
 l_direccion_re varchar(100);
 l_colonia_re varchar(100);
 l_ciudad_re varchar(100);
 l_estado_re varchar(100);
 l_cp_re varchar(100);
 l_direccion_co varchar(100);
 l_colonia_co varchar(100);
 l_ciudad_co varchar(100);
 l_estado_co varchar(100);
 l_cp_co varchar(100);
 l_pais_co varchar(100);
 l_municipio_co varchar(100);
 l_bandera_dom varchar(100);
 l_retorna varchar2(200):='Exito';
 l_contar number;
 l_secuencia number :=0;
 vl_msje Varchar2(250):='Exito al actualizar los datos ';

BEGIN
 SELECT COUNT(SPRADDR_PIDM)
 INTO l_contar
 FROM SPRADDR
 WHERE 1=1
 AND SPRADDR_PIDM = p_pidm
 AND SPRADDR_ATYP_CODE = p_bandera_dom;
 
 IF l_contar = 0 THEN 
 INSERT INTO SPRADDR 
 VALUES (p_pidm,
 p_bandera_dom,
 1,
 null,
 null,
 p_direccion_co,
 null,
 p_colonia_co,
 p_ciudad_co,
 p_estado_co,
 p_cp_co,
 p_municipio_co,
 p_pais_co,
 null,
 null,
 null,
 null,
 SYSDATE,
 USER,
 null,
 null,
 null,
 null,
 null,
 null,
 null,
 'ACTUALIZA_DOM',
 null,
 null,
 null,
 null,
 null,
 null,
 null
 ); 
 
 END IF; 
 
 IF l_contar > 0 THEN 
 
 select NVL (MAX (SPRADDR_SEQNO), 0) + 1
 INTO l_secuencia
 FROM SPRADDR
 WHERE SPRADDR_PIDM = p_pidm;
 
 
 UPDATE SPRADDR
 SET SPRADDR_STREET_LINE1 = p_direccion_co,
 SPRADDR_STREET_LINE3 = p_colonia_co,
 SPRADDR_CITY = p_ciudad_co,
 SPRADDR_STAT_CODE = p_estado_co,
 SPRADDR_CNTY_CODE = p_municipio_co,
 SPRADDR_ZIP = p_cp_co
 WHERE SPRADDR_PIDM = p_pidm
 AND SPRADDR_ATYP_CODE = p_bandera_dom;
 END IF; 
 
 commit;
 Return vl_msje;
 exception 
 when others then
 vl_msje:= 'Error al actualizar los datos de domicilio'; 
 END;


FUNCTION f_actualiza_canal(p_pidm in number, 
 p_appl in number, 
 p_vendedor_a in varchar2, 
 p_canal_a in varchar2, 
 p_vendedor_n in varchar2, 
 p_canal_n in varchar2
 ) return varchar2

is 

 l_retorna varchar2(200):='Exito';
 l_contar number;

begin

 if p_vendedor_n IS NOT NULL THEN
 
 Begin
 UPDATE SARACMT
 SET SARACMT_COMMENT_TEXT = p_vendedor_n
 WHERE SARACMT_PIDM = p_pidm
 AND SARACMT_APPL_NO = p_appl
 AND SARACMT_COMMENT_TEXT = p_vendedor_a;
 COMMIT; 

 End;
 
 end if;
 
 if p_canal_n IS NOT NULL THEN
 
 Begin
 UPDATE SARACMT
 SET SARACMT_COMMENT_TEXT = p_canal_n
 WHERE SARACMT_PIDM = p_pidm
 AND SARACMT_APPL_NO = p_appl
 AND SARACMT_COMMENT_TEXT = p_canal_a;
 COMMIT; 

 End;
 
 end if;
 
 
 if p_canal_n = 27 or p_canal_n = 15 or p_canal_n = 25 THEN 
 l_contar:=0; 
 BEGIN 
 SELECT COUNT(*) INTO l_contar
 FROM GORADID
 WHERE GORADID_PIDM = p_pidm
 AND GORADID_ADID_CODE = 'UTLE';
 END; 
 if l_contar = 0 THEN 
 Begin 
 INSERT INTO GORADID 
 VALUES (p_pidm,
 'Alumno de Empresarial',
 'UTLE',
 USER,
 SYSDATE,
 'Actualiza canal',
 null,
 null,
 null
 ); 
 commit;
 End; 
 end if;
 end if;
 
 if p_canal_n <> 27 and p_canal_n <> 15 and p_canal_n <> 25 THEN 
 l_contar:=0; 
 BEGIN 
 SELECT COUNT(*) INTO l_contar
 FROM GORADID
 WHERE GORADID_PIDM = p_pidm
 AND GORADID_ADID_CODE = 'UTLE';
 END; 
 if l_contar > 0 THEN 
 Begin 
 delete GORADID 
 where GORADID_PIDM = p_pidm
 AND GORADID_ADID_CODE = 'UTLE';
 commit;
 End; 
 end if;
 end if;
 

 
 If l_retorna = 'Exito' then
 commit;
 else rollback;
 End if;
 
 return (l_retorna);

end;

 FUNCTION f_bajadeudo  (p_pidm in number) RETURN PKG_ACTUALIZA_DATOS.cursor_out_bajadeudo --FER V1.03/10/2019 PKG_DASHBOARD_ALUMNO
 AS
 c_out_bajadeudo PKG_ACTUALIZA_DATOS.cursor_out_bajadeudo;

 BEGIN 
 open c_out_bajadeudo 
 FOR SELECT DISTINCT
 sgbstdn_pidm VL_PIDM,
 spriden_id VL_ID,
 b.spriden_first_name||' '||REPLACE(b.spriden_last_name,'/',' ') VL_NOMBRE_ALUMNO,
 sfbetrm_term_code VL_TERM,
 goremal_email_address VL_CORREO,
 sgbstdn_stst_code VL_ESTATUS,
 stvstst_desc VL_DESCRIP,
 sfbetrm_activity_date VL_ACTIVIDAD,--TRUNC (sgbstdn_activity_date) VL_ACTIVIDAD, 
 sorlcur_program VL_PROGRAMA,
 sztdtec_programa_comp VL_DESCRIP_PROGRA,
 sfbetrm_rgre_code VL_RAZON,
 stvrgre_desc VL_DESCRIP_RAZON
 FROM sgbstdn A, spriden B, sorlcur C, sfbetrm, stvstst, sztdtec, stvrgre, goremal --stvrgre
 WHERE 1=1
 AND sorlcur_program = sztdtec_program
 AND spriden_pidm = goremal_pidm
 AND sfbetrm_rgre_code = stvrgre_code
 AND sgbstdn_camp_code = sztdtec_camp_code
 AND sgbstdn_stst_code = stvstst_code
 AND a.sgbstdn_pidm = b.spriden_pidm
 AND c.sorlcur_pidm = sgbstdn_pidm
 AND sgbstdn_pidm= sfbetrm_pidm
 AND b.spriden_change_ind IS NULL
 AND c.sorlcur_levl_code = sgbstdn_levl_code
 AND c.sorlcur_curr_rule = sgbstdn_curr_rule_1
 AND c.sorlcur_coll_code = sgbstdn_coll_code_1
 AND c.sorlcur_term_code_ctlg = sgbstdn_term_code_ctlg_1
 AND c.sorlcur_degc_code = sgbstdn_degc_code_1 
 AND c.sorlcur_admt_code = sgbstdn_admt_code
 AND c.sorlcur_camp_code = sgbstdn_camp_code
 AND c. sorlcur_lmod_code = 'LEARNER'
 --AND SPRIDEN_ID in ('010012505')
 AND sgbstdn_pidm = p_pidm
 AND sfbetrm_rgre_code IN ('BA', 'RG', 'DA')
 AND goremal_emal_code = 'PRIN'
 AND a.sgbstdn_term_code_eff = (SELECT DISTINCT MAX (A1.sgbstdn_term_code_eff)
 FROM sgbstdn A1
 WHERE 1=1
 AND a.sgbstdn_pidm= a1.sgbstdn_pidm
 )
 AND c.sorlcur_seqno = (SELECT DISTINCT MAX (c1.sorlcur_seqno)
 FROM sorlcur c1
 WHERE 1=1
 AND c.sorlcur_pidm= c1.sorlcur_pidm
 AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code
 )
 ; 
 
 RETURN (c_out_bajadeudo);
 
 
 END;
 
 
 FUNCTION f_actu_bajadeudo (p_pidm IN NUMBER, p_periodo IN VARCHAR2, operador IN VARCHAR2) RETURN VARCHAR2 -- Fer V2.03/10/2019

 IS 

 l_error VARCHAR2 (2500) := 'EXITO';
 seq_sgrscmt NUMBER;
 
 BEGIN
 
 BEGIN
 UPDATE sfbetrm
 SET sfbetrm_rgre_code = 'RG',
 sfbetrm_activity_date = SYSDATE,
 sfbetrm_add_date = SYSDATE
 WHERE 1=1
 AND sfbetrm_pidm = p_pidm
-- AND sfbetrm_term_code = p_periodo
 AND sfbetrm_rgre_code in ('BA', 'DA');
 
 EXCEPTION
 WHEN OTHERS THEN
 l_error:= 'ERROR AL INSERTAR EL CÓDIGO DE RAZÓN: '||sqlerrm;
 END;
 
 if l_error = 'EXITO' then
 
 BEGIN
 SELECT NVL(MAX(sgrscmt_seq_no),0)+1
 INTO seq_sgrscmt
 FROM SGRSCMT
 WHERE 1=1
 AND sgrscmt_pidm = p_pidm
 AND sgrscmt_term_code = p_periodo;
 EXCEPTION WHEN OTHERS THEN
 l_error:='ERROR AL OBTENER SECUENCIA MAXIMA'||sqlerrm;
 END;
 
 if l_error = 'EXITO' then
 
 BEGIN
 
 INSERT INTO SGRSCMT 
 VALUES --SGRSCMT_PIDM, SGRSCMT_SEQ_NO, SGRSCMT_TERM_CODE, SGRSCMT_COMMENT_TEXT, SGRSCMT_ACTIVITY_DATE, SGRSCMT_SURROGATE_ID, SGRSCMT_VERSION, SGRSCMT_USER_ID, SGRSCMT_DATA_ORIGIN, SGRSCMT_VPDI_CODE
 (p_pidm,
 seq_sgrscmt,
 p_periodo,
 'CAMBIO_RAZON_ALUMNO_SIN_ADEUDO ' || operador,
 SYSDATE,
 NULL,
 NULL,
 operador,
 'DASHBOARD_SIU',
 NULL
 );
 
 EXCEPTION
 WHEN OTHERS THEN
 
 DBMS_OUTPUT.PUT_LINE('ERROR AL INSERTAR BITÁCORA');
 l_error:=('ERROR AL INSERTAR BITÁCORA '||sqlerrm||' PERIODO '||p_periodo);
 
 END;
 
 if l_error = 'EXITO' then
 
 commit;
 return(l_error);
 else
 
 rollback;
 return(l_error);
 
 end if;
 
 else
 rollback;
 return(l_error); 
 
 end if;
 
 else
 
 rollback;
 return(l_error); 
 
 
 END IF;
 

 
 END f_actu_bajadeudo;
--
--
 FUNCTION f_proyec_lazaro (p_pidm in number) RETURN PKG_ACTUALIZA_DATOS.cursor_out_proyec_lazaro --FER V2 21/09/2020
 AS
 c_out_proyec_lazaro PKG_ACTUALIZA_DATOS.cursor_out_proyec_lazaro;

 BEGIN 
 open c_out_proyec_lazaro 
 FOR SELECT DISTINCT
 spriden_pidm PIDM,
 spriden_id MATRICULA,
 b.spriden_first_name||' '||replace(b.spriden_last_name,'/',' ') NOMBRE_ALUMNO,
 goremal_email_address CORREO
 FROM spriden B,goremal
 WHERE 1=1
 AND b.spriden_pidm = goremal_pidm
 AND b.spriden_change_ind IS NULL
 AND goremal_emal_code = 'PRIN'
 AND b.spriden_pidm = p_pidm;
 
 RETURN (c_out_proyec_lazaro);
 
 
 END;

--
--
 FUNCTION f_consu_goradid (p_pidm in number) RETURN PKG_ACTUALIZA_DATOS.cursor_consu_goradid --FER V1. 03/10/2019
 AS
 c_out_consu_goradid PKG_ACTUALIZA_DATOS.cursor_consu_goradid;


BEGIN 

 OPEN c_out_consu_goradid 
 FOR SELECT 
 spriden_id VL_ID, 
 goradid_pidm VL_PIDM,
 goradid_adid_code VL_ATRIBUTO,
 gtvadid_desc VL_DESC,
 goradid_additional_id VL_INFORM
 FROM goradid, spriden, gtvadid
 WHERE 1=1
 AND goradid_pidm = spriden_pidm
 AND goradid_adid_code = gtvadid_code
 AND spriden_change_ind IS NULL
 AND goradid_pidm = p_pidm 
-- AND spriden_id = '010017225'
 ;

 RETURN (c_out_consu_goradid); 
 
END;

--
--
 FUNCTION f_inserta_goradid (p_pidm IN NUMBER, p_comentario varchar2, p_atributo IN VARCHAR2, p_operador varchar2) RETURN VARCHAR2 -- Fer V1.01/09/2020

 IS 

 l_error VARCHAR2 (2500) := 'EXITO';
 l_error_sgrscmt VARCHAR2 (2500) := 'EXITO';
 l_errormax_periodo VARCHAR2 (2500) := 'EXITO';
 l_error_insertsgrscmt VARCHAR2 (2500) := 'EXITO';
 l_max_periodo VARCHAR2 (2500):= NULL;
 l_seq_sgrscmt NUMBER:= NULL;
 l_max_goradid_surrogate NUMBER:= NULL;
 l_operador VARCHAR2 (2500) := NULL;
 l_contar_per NUMBER := NULL;
 l_maxsurrogate NUMBER;
 
BEGIN


 BEGIN

 SELECT (goradid_surrogate_id_sequence.NEXTVAL)
 INTO l_max_goradid_surrogate
 FROM dual
 WHERE 1=1;

 EXCEPTION WHEN OTHERS THEN
 dbms_output.put_line ('ERROR AL OBTENER MAXIMO SURROGATE '||sqlerrm);
 l_error:='ERROR AL OBTENER MAXIMO SURROGATE '||sqlerrm;

 END;

 IF l_error = 'EXITO' then 
 
 BEGIN

 INSERT INTO goradid 
 VALUES 
 (p_pidm,
 p_comentario,--'Dirección de Retención Académica',
 p_atributo, --'RECU',
 p_operador,
 SYSDATE,
 'SIU_V2',
 l_max_goradid_surrogate,
 NULL,
 NULL);
 
 EXCEPTION
 WHEN OTHERS THEN
 dbms_output.put_line('ERROR AL INSERTAR CÓDIGO EN GORADID '||SQLERRM); 
 l_error:= ('ERROR AL INSERTAR CÓDIGO EN GORADID'||sqlerrm);

 END;
 
 END IF;


 IF l_error = 'EXITO' then

 l_operador:='SE INSERTO CÓDIGO EN SPAIDEN '|| P_ATRIBUTO || ' OPERDOR: ' || p_operador;
 
 DBMS_OUTPUT.PUT_LINE(l_operador);
 
 END IF;
 
 BEGIN
 SELECT DISTINCT COUNT (sgbstdn_term_code_eff)
 INTO l_contar_per
 FROM sgbstdn A, spriden B, sorlcur C
 WHERE 1=1
 AND a.sgbstdn_pidm = b.spriden_pidm
 AND sorlcur_pidm = sgbstdn_pidm
 AND b.spriden_change_ind IS NULL
 AND c. sorlcur_lmod_code = 'LEARNER' -- AND spriden_id = '010215013'
 AND sorlcur_pidm = p_pidm
 AND a.sgbstdn_term_code_eff = (SELECT MAX (A1.sgbstdn_term_code_eff)
 FROM sgbstdn A1
 WHERE 1=1
 AND a.sgbstdn_pidm= a1.sgbstdn_pidm)
 AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
 FROM sorlcur c1
 WHERE 1=1
 AND c.sorlcur_pidm= c1.sorlcur_pidm
 AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code); 
 
 EXCEPTION WHEN OTHERS THEN
 dbms_output.put_line ('ERROR AL CONTAR EN LA FORMA SGBSTDN '||sqlerrm);
 l_errormax_periodo:='ERROR AL CONTAR EN LA FORMA SGBSTDN '||sqlerrm;
 
 END;
 
 
 IF l_contar_per >= 1 THEN 
 
 BEGIN
 SELECT NVL(MAX(sgrscmt_seq_no),0)+1
 INTO l_seq_sgrscmt
 FROM sgrscmt
 WHERE 1=1
 AND sgrscmt_pidm = p_pidm;
 
 EXCEPTION WHEN OTHERS THEN
 l_error_sgrscmt:='ERROR AL OBTENER SECUENCIA MAXIMA'||sqlerrm;
 END;
 

 BEGIN 
 
 SELECT DISTINCT sgbstdn_term_code_eff MAX_PERIODO
 INTO l_max_periodo
 FROM sgbstdn A, spriden B, sorlcur C
 WHERE 1=1
 AND a.sgbstdn_pidm = b.spriden_pidm
 AND sorlcur_pidm = sgbstdn_pidm
 AND b.spriden_change_ind IS NULL
 AND c. sorlcur_lmod_code = 'LEARNER' -- AND spriden_id = '010215013'
 AND sorlcur_pidm = p_pidm
 AND a.sgbstdn_term_code_eff = (SELECT MAX (A1.sgbstdn_term_code_eff)
 FROM sgbstdn A1
 WHERE 1=1
 AND a.sgbstdn_pidm= a1.sgbstdn_pidm)
 AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
 FROM sorlcur c1
 WHERE 1=1
 AND c.sorlcur_pidm= c1.sorlcur_pidm
 AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code); 
 
 EXCEPTION WHEN OTHERS THEN
 dbms_output.put_line ('ERROR AL OBTENER MÁXIMO PERIODO '||sqlerrm);
 l_errormax_periodo:='ERROR AL OBTENER MÁXIMO PERIODO '||sqlerrm;
 
 END;
 
 BEGIN
 
 SELECT NVL(MAX(SGRSCMT_SURROGATE_ID),0)+1
 INTO l_maxsurrogate
 FROM sgrscmt
 WHERE 1=1
 AND sgrscmt_pidm =P_PIDM;
 -- FGET_PIDM('010432825');
 
 EXCEPTION WHEN OTHERS THEN
 l_error_sgrscmt:='ERROR AL OBTENER MAXIMO SURROGATE'||sqlerrm;
 END;
 
 BEGIN
 
 INSERT INTO SGRSCMT 
 VALUES 
 (p_pidm,
 l_seq_sgrscmt,
 l_max_periodo,
 l_operador,
 SYSDATE,
 l_maxsurrogate,
 NULL,
 p_operador,
 'DASHBOARD_SIU',
 NULL);
 
 EXCEPTION
 WHEN OTHERS THEN
 
 DBMS_OUTPUT.PUT_LINE('ERROR AL INSERTAR BITÁCORA');
 l_error_insertsgrscmt:=('ERROR AL INSERTAR BITÁCORA '||sqlerrm||' PERIODO '||l_max_periodo);
 
 END;
 
 END IF; 


COMMIT;

RETURN(l_error);

END;

 
--
--
 FUNCTION f_elimina_goradid (p_pidm IN NUMBER, p_atributo IN VARCHAR2, p_operador varchar2) RETURN VARCHAR2 -- Fer V1.01/09/2020

 IS 

 l_error VARCHAR2 (2500) := 'EXITO';
 l_error_sgrscmt VARCHAR2 (2500) := 'EXITO';
 l_errormax_periodo VARCHAR2 (2500) := 'EXITO';
 l_error_insertsgrscmt VARCHAR2 (2500) := 'EXITO';
 l_max_periodo VARCHAR2 (2500):= NULL;
 l_seq_sgrscmt NUMBER:= NULL;
 l_operador VARCHAR2 (2500) := NULL;
 l_contar_per NUMBER := NULL;
 l_maxsurrogate number;
 
BEGIN


 BEGIN
 DELETE goradid 
 WHERE 1=1
 AND goradid_pidm = p_pidm
 AND goradid_adid_code = p_atributo; 
 
 
 EXCEPTION
 WHEN OTHERS THEN
 dbms_output.put_line('ERROR AL ELIMINAR CÓDIGO EN GORADID '||SQLERRM); 
 l_error:= ('ERROR AL ELIMINAR CÓDIGO EN GORADID '||sqlerrm);
 END;
 
 
 IF l_error = 'EXITO' then

 l_operador:='SE ELIMINO CÓDIGO EN SPAIDEN '|| P_ATRIBUTO || ' OPERDOR: ' || p_operador;
 
 DBMS_OUTPUT.PUT_LINE(l_operador);
 
 END IF;
 
 
 BEGIN
 
 
 SELECT DISTINCT COUNT (sgbstdn_term_code_eff)
 INTO l_contar_per
 FROM sgbstdn A, spriden B, sorlcur C
 WHERE 1=1
 AND a.sgbstdn_pidm = b.spriden_pidm
 AND sorlcur_pidm = sgbstdn_pidm
 AND b.spriden_change_ind IS NULL
 AND c. sorlcur_lmod_code = 'LEARNER' 
-- AND spriden_id = '010432825'
 AND sorlcur_pidm = p_pidm
 AND a.sgbstdn_term_code_eff = (SELECT MAX (A1.sgbstdn_term_code_eff)
 FROM sgbstdn A1
 WHERE 1=1
 AND a.sgbstdn_pidm= a1.sgbstdn_pidm)
 AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
 FROM sorlcur c1
 WHERE 1=1
 AND c.sorlcur_pidm= c1.sorlcur_pidm
 AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code); 
 
 EXCEPTION WHEN OTHERS THEN
 dbms_output.put_line ('ERROR AL CONTAR EN LA FORMA SGBSTDN '||sqlerrm);
 l_errormax_periodo:='ERROR AL CONTAR EN LA FORMA SGBSTDN '||sqlerrm;
 
 END;
 
 
 IF l_contar_per >= 1 THEN 
 
 BEGIN
 
 SELECT NVL(MAX(sgrscmt_seq_no),0)+1
 INTO l_seq_sgrscmt
 FROM sgrscmt
 WHERE 1=1
 AND sgrscmt_pidm =P_PIDM;
 -- FGET_PIDM('010432825');
 
 EXCEPTION WHEN OTHERS THEN
 l_error_sgrscmt:='ERROR AL OBTENER SECUENCIA MAXIMA'||sqlerrm;
 END;
 

 BEGIN 
 
 SELECT DISTINCT sgbstdn_term_code_eff MAX_PERIODO
 INTO l_max_periodo
 FROM sgbstdn A, spriden B, sorlcur C
 WHERE 1=1
 AND a.sgbstdn_pidm = b.spriden_pidm
 AND sorlcur_pidm = sgbstdn_pidm
 AND b.spriden_change_ind IS NULL
 AND c. sorlcur_lmod_code = 'LEARNER' 
-- AND spriden_id = '010432825'
 AND sorlcur_pidm = p_pidm
 AND a.sgbstdn_term_code_eff = (SELECT MAX (A1.sgbstdn_term_code_eff)
 FROM sgbstdn A1
 WHERE 1=1
 AND a.sgbstdn_pidm= a1.sgbstdn_pidm)
 AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
 FROM sorlcur c1
 WHERE 1=1
 AND c.sorlcur_pidm= c1.sorlcur_pidm
 AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code); 
 
 
 EXCEPTION WHEN OTHERS THEN
 dbms_output.put_line ('ERROR AL OBTENER MÁXIMO PERIODO '||sqlerrm);
 l_errormax_periodo:='ERROR AL OBTENER MÁXIMO PERIODO '||sqlerrm;
 
 END;
 
 BEGIN
 
 SELECT NVL(MAX(SGRSCMT_SURROGATE_ID),0)+1
 INTO l_maxsurrogate
 FROM sgrscmt
 WHERE 1=1
 AND sgrscmt_pidm =P_PIDM;
 -- FGET_PIDM('010432825');
 
 EXCEPTION WHEN OTHERS THEN
 l_error_sgrscmt:='ERROR AL OBTENER MAXIMO SURROGATE'||sqlerrm;
 END;
 
 BEGIN
 
 INSERT INTO SGRSCMT 
 VALUES 
 (p_pidm,
 l_seq_sgrscmt,
 l_max_periodo,
 l_operador,
 SYSDATE,
 l_maxsurrogate,
 NULL,
 p_operador,
 'DASHBOARD_SIU',
 NULL);
 
 EXCEPTION
 WHEN OTHERS THEN
 
 DBMS_OUTPUT.PUT_LINE('ERROR AL INSERTAR BITÁCORA'||p_pidm|| l_seq_sgrscmt||l_max_periodo||l_operador);
 l_error_insertsgrscmt:=('ERROR AL INSERTAR BITÁCORA '||sqlerrm||' PERIODO '||l_max_periodo);
 
 END;
 
 END IF;
 COMMIT;

RETURN(l_error);

END;

--
--
 FUNCTION f_generales_ad (p_pidm in number) RETURN PKG_ACTUALIZA_DATOS.cursor_out_generales_ad --FER V1.25/02/2020
 AS
 c_out_generales_ad PKG_ACTUALIZA_DATOS.cursor_out_generales_ad;

 BEGIN 
 open c_out_generales_ad
 FOR SELECT DISTINCT
 sgbstdn_pidm PIDM,
 spriden_id ID,
 c.sorlcur_term_code TERM,
 b.spriden_first_name||' '||replace(b.spriden_last_name,'/',' ') NOMBRE_ALUMNO,
 goremal_email_address CORREO,
 sgbstdn_stst_code ESTATUS,
 stvstst_desc DESCRIP, 
 sorlcur_program PROGRAMA,
 sztdtec_programa_comp DESCRIP_PROGRA, 
 sorlcur_start_date FECHA_INICIO, 
 sorlcur_levl_code NIVEL,
 (SELECT STVLEVL_DESC FROM stvlevl WHERE 1=1 AND stvlevl_code = c.sorlcur_levl_code) DESCRIPCION_NIVEL,
 sorlcur_camp_code CAMPUS,
 (SELECT stvcamp_desc FROM stvcamp WHERE 1=1 AND c.sorlcur_camp_code = stvcamp_code) DESCRIPCION_CAMP 
 FROM sgbstdn A, spriden B, sorlcur C, stvstst, sztdtec, goremal
 WHERE 1=1
 AND sorlcur_program = sztdtec_program
 AND a.sgbstdn_pidm = b.spriden_pidm
 AND sgbstdn_stst_code = stvstst_code
 AND spriden_pidm = goremal_pidm
 AND c.sorlcur_pidm(+) = sgbstdn_pidm
 AND b.spriden_change_ind IS NULL
 AND c.sorlcur_levl_code = sgbstdn_levl_code
 AND c.sorlcur_curr_rule = sgbstdn_curr_rule_1
 AND c.sorlcur_coll_code = sgbstdn_coll_code_1
 AND c.sorlcur_term_code_ctlg = sgbstdn_term_code_ctlg_1
 AND c.sorlcur_degc_code = sgbstdn_degc_code_1 
 AND c.sorlcur_admt_code = sgbstdn_admt_code
 AND c.sorlcur_camp_code = sgbstdn_camp_code
 AND c. sorlcur_lmod_code = 'LEARNER'
-- AND SPRIDEN_ID in ('010017225')
 AND goremal_emal_code = 'PRIN'
 AND sgbstdn_pidm = p_pidm
 AND a.sgbstdn_term_code_eff = (SELECT DISTINCT MAX (A1.sgbstdn_term_code_eff)
 FROM sgbstdn A1
 WHERE 1=1
 AND a.sgbstdn_pidm= a1.sgbstdn_pidm
 AND a.sgbstdn_program_1= a1.sgbstdn_program_1
 AND a.sgbstdn_term_code_ctlg_1 = a1.sgbstdn_term_code_ctlg_1)
 AND c.sorlcur_seqno = (SELECT DISTINCT MAX (c1.sorlcur_seqno)
 FROM sorlcur c1
 WHERE 1=1
 AND c.sorlcur_pidm= c1.sorlcur_pidm
 AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code
 AND c.sorlcur_program = c1.sorlcur_program
 AND c.sorlcur_term_code_ctlg= c1.sorlcur_term_code_ctlg);
 
 RETURN (c_out_generales_ad);
 
 
 END;

--
-- 
 FUNCTION f_datos_generales (p_pidm in number) RETURN PKG_ACTUALIZA_DATOS.cursor_out_datos_generales --FER V2.20/03/2020
 AS
 c_out_datos_generales PKG_ACTUALIZA_DATOS.cursor_out_datos_generales;

 BEGIN 
 open c_out_datos_generales 
 FOR SELECT 
 PIDM,
 ID,
 TERM,
 NOMBRE_ALUMNO,
 CORREO,
 ESTATUS,
 DESCRIP, 
 PROGRAMA,
 DESCRIP_PROGRA
 FROM
 (SELECT DISTINCT
 sgbstdn_pidm PIDM,
 spriden_id ID,
 c.sorlcur_term_code TERM,
 b.spriden_first_name||' '||replace(b.spriden_last_name,'/',' ') NOMBRE_ALUMNO,
 goremal_email_address CORREO,
 sgbstdn_stst_code ESTATUS,
 stvstst_desc DESCRIP, 
 sorlcur_program PROGRAMA,
 sztdtec_programa_comp DESCRIP_PROGRA
 FROM sgbstdn A, spriden B, sorlcur C, stvstst, sztdtec, goremal
 WHERE 1=1
 AND sorlcur_program = sztdtec_program
 AND a.sgbstdn_pidm = b.spriden_pidm
 AND sgbstdn_stst_code = stvstst_code
 AND spriden_pidm = goremal_pidm
 AND c.sorlcur_pidm(+) = sgbstdn_pidm
 AND b.spriden_change_ind IS NULL
 AND c.sorlcur_levl_code = sgbstdn_levl_code
 AND c.sorlcur_term_code_ctlg = sgbstdn_term_code_ctlg_1
 AND c.sorlcur_camp_code = sgbstdn_camp_code
 AND c. sorlcur_lmod_code = 'LEARNER'
 --AND SPRIDEN_ID in ('010243647')
 AND goremal_emal_code = 'PRIN'
 AND a.sgbstdn_stst_code IN ('MA', 'PR', 'AS', 'EG')
 --AND sgbstdn_pidm = P_PIDM
 AND c.sorlcur_program in (SELECT zstpara_param_id
 FROM zstpara
 WHERE 1=1
 AND zstpara_mapa_id = 'MATERIAS_OPTATI'
 AND zstpara_param_desc = '011542')
 AND spriden_id NOT IN (SELECT DISTINCT (zstpara_param_id)
 FROM zstpara
 WHERE 1=1
 AND spriden_id = zstpara_param_id) 
 AND a.sgbstdn_term_code_eff = (SELECT DISTINCT MAX (A1.sgbstdn_term_code_eff)
 FROM sgbstdn A1
 WHERE 1=1
 AND a.sgbstdn_pidm= a1.sgbstdn_pidm)
 AND c.sorlcur_seqno = (SELECT DISTINCT MAX (c1.sorlcur_seqno)
 FROM sorlcur c1
 WHERE 1=1
 AND c.sorlcur_pidm= c1.sorlcur_pidm
 AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code)
 UNION ALL
 SELECT DISTINCT
 sgbstdn_pidm PIDM,
 spriden_id ID,
 c.sorlcur_term_code TERM,
 b.spriden_first_name||' '||replace(b.spriden_last_name,'/',' ') NOMBRE_ALUMNO,
 goremal_email_address CORREO,
 sgbstdn_stst_code ESTATUS,
 stvstst_desc DESCRIP, 
 sorlcur_program PROGRAMA,
 sztdtec_programa_comp DESCRIP_PROGRA
 FROM sgbstdn A, spriden B, sorlcur C, stvstst, sztdtec, goremal
 WHERE 1=1
 AND sorlcur_program = sztdtec_program
 AND a.sgbstdn_pidm = b.spriden_pidm
 AND sgbstdn_stst_code = stvstst_code
 AND spriden_pidm = goremal_pidm
 AND c.sorlcur_pidm(+) = sgbstdn_pidm
 AND b.spriden_change_ind IS NULL
 AND c.sorlcur_levl_code = sgbstdn_levl_code
 AND c.sorlcur_term_code_ctlg = sgbstdn_term_code_ctlg_1
 AND c.sorlcur_camp_code = sgbstdn_camp_code
 AND c. sorlcur_lmod_code = 'LEARNER'
 --AND SPRIDEN_ID in ('010243647')
 AND goremal_emal_code = 'PRIN'
 AND a.sgbstdn_stst_code IN ('MA', 'PR', 'AS', 'EG')
 -- AND sgbstdn_pidm = P_PIDM
 AND c.sorlcur_program in (SELECT zstpara_param_id
 FROM zstpara
 WHERE 1=1
 AND zstpara_mapa_id = 'MATERIAS_OPTATI'
                                           AND zstpara_param_desc = '000000')
                 AND spriden_id NOT IN (SELECT DISTINCT (zstpara_param_id)
                                        FROM zstpara
                                        WHERE 1=1
                                        AND spriden_id = zstpara_param_id)              
                 AND a.sgbstdn_term_code_eff = (SELECT DISTINCT MAX (A1.sgbstdn_term_code_eff)
                                             FROM sgbstdn A1
                                             WHERE 1=1
                                             AND a.sgbstdn_pidm= a1.sgbstdn_pidm)
                 AND c.sorlcur_seqno = (SELECT DISTINCT MAX (c1.sorlcur_seqno)
                                             FROM sorlcur c1
                                             WHERE 1=1
                                             AND c.sorlcur_pidm= c1.sorlcur_pidm
                                             AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code))
             WHERE 1=1
             AND PIDM  = P_PIDM;
                         
       RETURN (c_out_datos_generales);
       
       
  END;

--
--
   FUNCTION f_mat_optativa (p_matricula VARCHAR2) RETURN PKG_ACTUALIZA_DATOS.cursor_out_mat_optativa  --FER V2.20/03/2020
           AS
                c_out_mat_optativa PKG_ACTUALIZA_DATOS.cursor_out_mat_optativa;

BEGIN 
     open c_out_mat_optativa            
       FOR             SELECT DISTINCT 
                  smrarul_subj_code||smrarul_crse_numb_low MATERIA, 
                  scrsyln_long_course_title DESCRIP_MAT
           FROM smrpaap, smracaa, smbarul,smrarul, scrsyln, tztprog
           WHERE 1=1
           AND smrarul_subj_code||smrarul_crse_numb_low = scrsyln_subj_code||scrsyln_crse_numb
           AND smrpaap_term_code_eff = smracaa_term_code_eff
           AND smrpaap_term_code_eff = smbarul_term_code_eff
           AND smbarul_term_code_eff = smrarul_term_code_eff
           AND smrpaap_area = smracaa_area
           AND smrpaap_area = smbarul_area
           AND smracaa_area = smrarul_area
           AND smrpaap_program = PROGRAMA
           AND smracaa_term_code_eff = CTLG
           AND smrpaap_program in (SELECT zstpara_param_id
                                   FROM zstpara
                                   WHERE 1=1
                                   AND zstpara_mapa_id = 'MATERIAS_OPTATI'
                                   AND zstpara_param_desc = '011542')
           AND ESTATUS IN ('MA', 'PR', 'AS', 'EG')
           --AND MATRICULA = '010053086'
           AND smrpaap_area IN (SELECT zstpara_param_valor
                                FROM zstpara
                                WHERE 1=1
                                AND ZSTPARA_MAPA_ID = 'MATERIAS_OPTATI'
                                AND ZSTPARA_PARAM_DESC = '011542')
           AND MATRICULA = p_matricula
           AND smrarul_subj_code||smrarul_crse_numb_low NOT IN ('O1DE154','O1DE149')
           UNION ALL
           SELECT DISTINCT 
                  smrarul_subj_code||smrarul_crse_numb_low MATERIA, 
                  scrsyln_long_course_title DESCRIP_MAT
           FROM smrpaap, smracaa, smbarul,smrarul, scrsyln, tztprog
           WHERE 1=1
           AND smrarul_subj_code||smrarul_crse_numb_low = scrsyln_subj_code||scrsyln_crse_numb
           AND smrpaap_term_code_eff = smracaa_term_code_eff
           AND smrpaap_term_code_eff = smbarul_term_code_eff
           AND smbarul_term_code_eff = smrarul_term_code_eff
           AND smrpaap_area = smracaa_area
           AND smrpaap_area = smbarul_area
           AND smracaa_area = smrarul_area
           AND smrpaap_program = PROGRAMA
           AND smracaa_term_code_eff = CTLG
           AND smrpaap_program in (SELECT zstpara_param_id
                                   FROM zstpara
                                   WHERE 1=1
                                   AND zstpara_mapa_id = 'MATERIAS_OPTATI'
                                   AND zstpara_param_desc = '000000')
           AND smrpaap_area in (SELECT zstpara_param_valor
                                FROM zstpara
                                WHERE 1=1
                                AND ZSTPARA_MAPA_ID = 'MATERIAS_OPTATI'
                                AND ZSTPARA_PARAM_DESC = '000000')
           AND ESTATUS IN ('MA', 'PR', 'AS', 'EG')
           --AND MATRICULA = '010053086'
           AND MATRICULA = p_matricula
           AND smrarul_subj_code||smrarul_crse_numb_low NOT IN ('O1DE154','O1DE149')
           ORDER BY 1;

     RETURN (c_out_mat_optativa);

END;

--
--

    FUNCTION  f_inser_mat_opt (p_matricula VARCHAR2,p_materia VARCHAR2,p_usuario VARCHAR2 )RETURN VARCHAR2 -- Fer V2.20/03/2020

    IS 
    
l_contar NUMBER:= NULL;
l_secuencia NUMBER:= NULL;
l_error VARCHAR2 (1000) := 'EXITO';
l_contar_2 NUMBER:= NULL;
l_max_periodo VARCHAR2 (100):= NULL;
l_seq_sgrscmt NUMBER := NULL;
l_pidm NUMBER:= NULL; 


BEGIN

    BEGIN 

    SELECT COUNT (zstpara_param_id)
    INTO l_contar
    FROM zstpara
    WHERE 1=1
    AND zstpara_mapa_id = 'NOVER_MAT_DASHB'
    AND zstpara_param_id = p_matricula;

    DBMS_OUTPUT.PUT_LINE('CONTAR : '||l_contar);

    END;
    

        IF l_contar <= 5 THEN
        
            l_contar_2 := NULL; 
        
            BEGIN 
            
                SELECT DISTINCT COUNT (smrarul_subj_code||smrarul_crse_numb_low) 
                INTO l_contar_2
                FROM smrpaap, smracaa, smbarul,smrarul, scrsyln, tztprog
                WHERE 1=1
                AND smrarul_subj_code||smrarul_crse_numb_low = scrsyln_subj_code||scrsyln_crse_numb
                AND smrpaap_term_code_eff = smracaa_term_code_eff
                AND smrpaap_term_code_eff = smbarul_term_code_eff
                AND smbarul_term_code_eff = smrarul_term_code_eff
                AND smrpaap_area = smracaa_area
                AND smrpaap_area = smbarul_area
                AND smracaa_area = smrarul_area
                AND smrpaap_program = PROGRAMA
                AND smracaa_term_code_eff = CTLG
                AND smrpaap_program IN (SELECT zstpara_param_id
                                        FROM zstpara
                                        WHERE 1=1
                                        AND zstpara_mapa_id = 'MATERIAS_OPTATI')
                AND smrpaap_area IN (SELECT zstpara_param_valor
                                     FROM zstpara
                                     WHERE 1=1
                                     AND zstpara_mapa_id = 'MATERIAS_OPTATI') 
                --AND MATRICULA = '010000454'
                AND smrarul_subj_code||smrarul_crse_numb_low = p_materia
                AND MATRICULA = p_matricula
                AND smrarul_subj_code||smrarul_crse_numb_low NOT IN ('O1DE154','O1DE149');
                                            
                                            DBMS_OUTPUT.PUT_LINE( 'CONTAR 2: '|| l_contar_2);
                                                
            EXCEPTION 
            WHEN OTHERS THEN
            l_error := 'ERROR: MATERIA OPTATIVA NO EXISTENTE PARA EL PROGRAMA DEL ALUMNO' ||sqlerrm;
            DBMS_OUTPUT.PUT_LINE('ERROR: MATERIA OPTATIVA NO EXISTENTE PARA EL PROGRAMA DEL ALUMNO'||l_error);
        
            END;
            
            
            IF l_contar_2 = 0 THEN 
            
                l_error := 'MATERIA OPTATIVA NO EXISTENTE PARA EL PROGRAMA DEL ALUMNO';
                  DBMS_OUTPUT.PUT_LINE ('MATERIA OPTATIVA NO EXISTENTE PARA EL PROGRAMA DEL ALUMNO');
            
            END IF; 
                
                
                IF l_contar_2 = 1 THEN
                
                   BEGIN 
                   
                    SELECT spriden_pidm l_pidm
                    INTO l_pidm
                    FROM spriden
                    WHERE 1=1
                    AND spriden_change_ind IS NULL
                    AND spriden_id = p_matricula;
                    
                    dbms_output.put_line(l_pidm); 
                   
                   END;                         
                
                    BEGIN 
                
                
                    SELECT MAX (zstpara_param_sec) +1 SECUENCIA
                    INTO l_secuencia
                    FROM zstpara
                    WHERE 1=1
                    AND zstpara_mapa_id = 'NOVER_MAT_DASHB';

                    DBMS_OUTPUT.PUT_LINE('MAXIMA SECUENCIA: '||l_secuencia);  

                    END;  
            
            
            
                    BEGIN 
                    
                    INSERT INTO zstpara
                    VALUES 
                    ('NOVER_MAT_DASHB',        --ZSTPARA_MAPA_ID
                     l_secuencia,              --ZSTPARA_PARAM_SEC
                     p_matricula,              --ZSTPARA_PARAM_ID
                     'UTLLIDDFED',             --ZSTPARA_PARAM_DESC
                     p_materia,                --ZSTPARA_PARAM_VALOR
                     SYSDATE,                  --ZSTPARA_PARAM_ACT_DATE
                     SYSDATE,                  --ZSTPARA_PARAM_VIG_DATE
                     p_usuario);               --ZSTPARA_PARAM_USER

                    EXCEPTION 
                    WHEN OTHERS THEN
                    l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP ' ||sqlerrm;
                    DBMS_OUTPUT.PUT_LINE('ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP '||l_error);
                       
                    END;
                    
                    BEGIN 
               
                       SELECT DISTINCT sgbstdn_term_code_eff MAX_PERIODO
                       INTO l_max_periodo
                       FROM sgbstdn A, spriden B, sorlcur C
                       WHERE 1=1
                       AND a.sgbstdn_pidm = b.spriden_pidm
                       AND sorlcur_pidm = sgbstdn_pidm
                       AND b.spriden_change_ind IS NULL
                       AND c. sorlcur_lmod_code =  'LEARNER'
                --       AND spriden_id = '010215013'
                       AND sorlcur_pidm = l_pidm
                       AND a.sgbstdn_term_code_eff = (SELECT MAX (A1.sgbstdn_term_code_eff)
                                                      FROM sgbstdn A1
                                                      WHERE 1=1
                                                      AND a.sgbstdn_pidm= a1.sgbstdn_pidm)
                       AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
                                              FROM sorlcur c1
                                              WHERE 1=1
                                              AND c.sorlcur_pidm= c1.sorlcur_pidm
                                              AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code);
                    

                    EXCEPTION WHEN OTHERS THEN
                       dbms_output.put_line ('ERROR AL OBTENER MÁXIMO PERIODO '||sqlerrm);
                       l_error:='ERROR AL OBTENER MÁXIMO PERIODO '||sqlerrm;
                    
                    END;
               
                    l_seq_sgrscmt := NULL;                      
               
                       BEGIN
                       
                           SELECT NVL(MAX(sgrscmt_seq_no),0)+1
                           INTO l_seq_sgrscmt
                           FROM sgrscmt
                           WHERE 1=1
                           AND sgrscmt_pidm  = l_pidm
                           AND sgrscmt_term_code = l_max_periodo;
                           
                       EXCEPTION WHEN OTHERS THEN
                         dbms_output.put_line ('ERROR AL OBTENER SECUENCIA MAXIMA'||sqlerrm);
                         l_error:='ERROR AL OBTENER SECUENCIA MAXIMA'||sqlerrm;
                         
                       END;
                       

                       BEGIN 
                       
                           INSERT INTO sgrscmt 
                           VALUES 
                             (l_pidm,
                              l_seq_sgrscmt,
                              l_max_periodo,
                              ' SE OCULTA  MATERIA OPTATIVA ' || ' " ' ||p_materia || ' " ' || ' ACTUALIZADO POR: ' || ' " ' || p_usuario || ' " ',
                              SYSDATE,
                              NULL,
                              NULL,
                              p_usuario,
                              'ACTU_DATOS_SIU',
                              NULL);
                                        
                       EXCEPTION
                       WHEN OTHERS THEN
                              
                           DBMS_OUTPUT.PUT_LINE('ERROR AL INSERTAR BITÁCORA');
                           l_error:=('ERROR AL INSERTAR BITÁCORA '||sqlerrm||' PERIODO '||l_max_periodo);

                       END;
                    
                END IF;     
        
            
            
          COMMIT;            
        
        ELSIF  l_contar > 4 THEN
        
            l_error:=('ALUMNO CUENTA CON MATERIAS EN EL AGRUPADOR ');
            DBMS_OUTPUT.PUT_LINE (l_error);
            
        
        END IF;

RETURN (l_error);

END;

--
--
/******************************************************************************
   NAME:       F_INSERTA_PLAN_CP
   PURPOSE:    Cambio de plan en paquetería dinámicas y escalonados.  

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/09/2022  FND@Create       1. Creación de la función.

   NOTES:     Cuando se cambia el plan de estudios del alumno.
              
******************************************************************************   
   MARCAS DE CAMBIO:
   No. 1
   Clave de cambio: 001-080902022-FND
   Fecha: 08/09/2022
   Autor: FND@Create
   Descripción: Asignación de variable numérica a caracter para el manejo del 
                28 de Febrero.
******************************************************************************
   No. 2
   Clave de cambio: 002-15092022-FND
   Fecha: 15/09/2022
   Autor: FND@Update
   Descripción: Asignación de variable numérica a caracter para el manejo de 
                meses.
******************************************************************************   

******************************************************************************/
FUNCTION F_INSERTA_PLAN_CP (   P_PIDM           NUMBER,  
                               P_PERIODO        VARCHAR2, 
                               P_MONTO          NUMBER, 
                               P_DETAIL_CODE    VARCHAR2, 
                               P_DETAIL_DESC    VARCHAR2, 
                               P_MONEDA         VARCHAR2 DEFAULT NULL,
                               P_VIGENCIA       NUMBER,
                               P_SOLI           NUMBER,
                               P_CAMBIO         NUMBER
                               ) RETURN VARCHAR2 IS
/*
proceso que ocupa el pkg_resa  para la insercion de planes  al momento de  hacer el cambio de solicitud.
*/

V_MONEDA            VARCHAR2(10);
VL_MES              NUMBER:=0;
VL_ANO              NUMBER:=0; 
VL_VENCIMIENTO      DATE;
VL_VIGENCIA         VARCHAR2(10);
LV_TRAN_NUM_2       NUMBER;
VL_VIGENCIA_PARA    VARCHAR2(4);
VL_PROPEDEUTICO     NUMBER;
LV_TRAN_NUM         NUMBER;
VL_ERROR            VARCHAR2(250):= 'EXITO';
VL_COMPLE_MES       NUMBER;
VL_MES_CHAR         VARCHAR2(10);




 BEGIN

  
    BEGIN
                
        SELECT ZSTPARA_PARAM_VALOR
        INTO VL_VIGENCIA_PARA
        FROM ZSTPARA
        WHERE ZSTPARA_MAPA_ID = 'VIG_ACCESORIO'
        AND ZSTPARA_PARAM_ID = SUBSTR(P_DETAIL_CODE,3,2);
                
    EXCEPTION
        WHEN OTHERS THEN    
            VL_VIGENCIA_PARA := NULL;
    END;
            
    BEGIN
            
        UPDATE TZFACCE
           SET TZFACCE_FLAG = 1
         WHERE TZFACCE_PIDM = P_PIDM
           AND TZFACCE_DESC != 'CAMBIO DE PLAN'||P_CAMBIO;       
    END;
    
    IF P_DETAIL_CODE IS NOT NULL THEN
      IF P_DETAIL_CODE != 'PRIM' THEN  
        BEGIN                 
                          
            FOR C IN (  
                      
                       SELECT TO_CHAR( SORLCUR_START_DATE,'mm') MES,
                              TO_CHAR(SORLCUR_START_DATE,'YYYY')ANO,
                              (DECODE (SUBSTR (SARADAP_RATE_CODE, 4, 1), 'A', '15', 'B', '30', 'C', '10'))VIGENCIA,
                              SORLCUR_PROGRAM,
                              SORLCUR_START_DATE,
                              SORLCUR_KEY_SEQNO STUDY,
                              SORLCUR_CAMP_CODE CAMPUS,
                              SORLCUR_LEVL_CODE NIVEL
                        FROM SORLCUR A,SARADAP 
                        WHERE A.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                        AND A.SORLCUR_ROLL_IND  = 'N'
                       AND SARADAP_PIDM = A.SORLCUR_PIDM  
                       AND SARADAP_APPL_NO = A.SORLCUR_KEY_SEQNO
                       AND SARADAP_APPL_NO = P_SOLI
                       AND SARADAP_PIDM = P_PIDM      
                                       
          )LOOP
                            
            IF VL_VIGENCIA_PARA IS NULL THEN
                                    
              VL_MES:= TO_NUMBER(C.MES)+((P_VIGENCIA)-1);
              VL_ANO:= C.ANO;
              VL_VIGENCIA:= C.VIGENCIA;  
                                    
            ELSE      
                
                BEGIN
                    
                    SELECT ZSTPARA_PARAM_VALOR
                    INTO VL_VIGENCIA_PARA
                    FROM ZSTPARA
                    WHERE ZSTPARA_MAPA_ID = 'VIG_ACCESORIO'
                    AND ZSTPARA_PARAM_ID = SUBSTR(P_DETAIL_CODE,3,2)
                    AND ZSTPARA_PARAM_VALOR != 1;
                    
                    
                EXCEPTION
                WHEN OTHERS THEN    
                 VL_VIGENCIA_PARA := NULL;
                END;
                      
                IF VL_VIGENCIA_PARA IS NULL THEN
                                    
                 VL_MES:= TO_NUMBER(C.MES)+((P_VIGENCIA)-1);
                 VL_ANO:= C.ANO;
                 VL_VIGENCIA:= C.VIGENCIA; 
                      
                ELSE
                                                
                      VL_MES:= TO_NUMBER(C.MES)+(TO_NUMBER(VL_VIGENCIA_PARA)-1);
                      VL_ANO:= C.ANO;
                      VL_VIGENCIA:= C.VIGENCIA;
                      
                END IF;        
                                    
            END IF;   
                                
            IF TO_NUMBER(TO_CHAR(C.SORLCUR_START_DATE,'DD')) > 20 THEN             
                VL_MES:= VL_MES+1;             
            END IF;
                            
                         
            BEGIN
                                        
                SELECT SZTPTRM_PROPEDEUTICO
                INTO VL_PROPEDEUTICO
                FROM SZTPTRM A
                WHERE A.SZTPTRM_PROGRAM = C.SORLCUR_PROGRAM 
                AND A.SZTPTRM_TERM_CODE  = P_PERIODO
                AND A.SZTPTRM_PTRM_CODE IN (SELECT SOBPTRM_PTRM_CODE
                                            FROM SOBPTRM
                                            WHERE SOBPTRM_TERM_CODE = A.SZTPTRM_TERM_CODE
                                            AND  SOBPTRM_START_DATE = C.SORLCUR_START_DATE );    
                                    
            EXCEPTION
            WHEN OTHERS THEN
            VL_PROPEDEUTICO := 0; 
            END;

            IF VL_PROPEDEUTICO >= 1 THEN
                --VL_MES:= TO_CHAR(TO_DATE(VL_MES,'MM')+1);
                VL_MES:= VL_MES+1;
            END IF;
            
/* Clave de cambio: 002-15092022-FND */ 
            
            BEGIN

                IF VL_MES = 1 THEN VL_MES_CHAR := '01'; VL_ANO := VL_ANO; END IF;
                                                                       
                IF VL_MES = 2 THEN VL_MES_CHAR := '02'; VL_ANO := VL_ANO; END IF; 
                                                                       
                IF VL_MES = 3 THEN VL_MES_CHAR := '03'; VL_ANO := VL_ANO; END IF;
                                                                       
                IF VL_MES = 4 THEN VL_MES_CHAR := '04'; VL_ANO := VL_ANO; END IF;
                                                                       
                IF VL_MES = 5 THEN VL_MES_CHAR := '05'; VL_ANO := VL_ANO; END IF; 
                                                                       
                IF VL_MES = 6 THEN VL_MES_CHAR := '06'; VL_ANO := VL_ANO; END IF;
                                        
                IF VL_MES = 7 THEN VL_MES_CHAR := '07'; VL_ANO := VL_ANO; END IF;
                                        
                IF VL_MES = 8 THEN VL_MES_CHAR := '08'; VL_ANO := VL_ANO; END IF;
                                        
                IF VL_MES = 9 THEN VL_MES_CHAR := '09'; VL_ANO := VL_ANO; END IF;
                                        
                IF VL_MES = 10 THEN VL_MES_CHAR := '10'; VL_ANO := VL_ANO; END IF;
                                        
                IF VL_MES = 11 THEN VL_MES_CHAR := '11'; VL_ANO := VL_ANO; END IF;
                                        
                IF VL_MES = 12 THEN VL_MES_CHAR := '12'; VL_ANO := VL_ANO; END IF;
                
                IF VL_MES = 13 THEN VL_MES_CHAR := '01'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF;
                                                                       
                IF VL_MES = 14 THEN VL_MES_CHAR := '02'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF; 
                                                                       
                IF VL_MES = 15 THEN VL_MES_CHAR := '03'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF;
                                                                       
                IF VL_MES = 16 THEN VL_MES_CHAR := '04'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF;
                                                                       
                IF VL_MES = 17 THEN VL_MES_CHAR := '05'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF; 
                                                                       
                IF VL_MES = 18 THEN VL_MES_CHAR := '06'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF;
                                        
                IF VL_MES = 19 THEN VL_MES_CHAR := '07'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF;
                                        
                IF VL_MES = 20 THEN VL_MES_CHAR := '08'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF;
                                        
                IF VL_MES = 21 THEN VL_MES_CHAR := '09'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF;
                                        
                IF VL_MES = 22 THEN VL_MES_CHAR := '10'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF;
                                        
                IF VL_MES = 23 THEN VL_MES_CHAR := '11'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF;
                                        
                IF VL_MES = 24 THEN VL_MES_CHAR := '12'; VL_ANO := TO_CHAR(TO_NUMBER(VL_ANO) + 1); END IF;
                
--------------------------------- Hasta aquí se ha manejado los meses y años en tipo de dato numérico
                                
            EXCEPTION 
            WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR (-20002,'Contando 4 <>'||SQLERRM);                                       
            END;

/* Clave de cambio: 001-08092022-FND */ 
                    
            IF VL_VIGENCIA = '30' THEN
            VL_VENCIMIENTO := TO_DATE((CASE VL_MES_CHAR WHEN '02' THEN '28' ELSE ''||VL_VIGENCIA END)||'/'|| VL_MES_CHAR||'/'||VL_ANO||'','DD/MM/YYYY');
            ELSE
            VL_VENCIMIENTO := TO_DATE(''||VL_VIGENCIA||'/'||VL_MES_CHAR||'/'||VL_ANO||'','DD/MM/YYYY');
            END IF;
                      
/* Fin Clave de cambio: 001-08092022-FND */
            
/* Fin Clave de cambio: 002-15092022-FND */

            BEGIN
                  SELECT NVL(MAX (TBRACCD_TRAN_NUMBER),0)  +1
                  INTO  LV_TRAN_NUM
                  FROM  TBRACCD
                  WHERE TBRACCD_PIDM = P_PIDM;
                                        
            EXCEPTION
            WHEN OTHERS  THEN 
            LV_TRAN_NUM := 1;
            END;
            
            IF  V_MONEDA  IS NULL  THEN

              BEGIN
                  
                SELECT TVRDCTX_CURR_CODE
                INTO V_MONEDA
                FROM TAISMGR.TVRDCTX
                WHERE TVRDCTX_DETC_CODE  = P_DETAIL_CODE;

              EXCEPTION
              WHEN NO_DATA_FOUND THEN 
              V_MONEDA  := 'MXN';
              END;

            END IF;       
                            
            IF LV_TRAN_NUM <> 0 THEN
                                    
                IF  VL_VIGENCIA_PARA IS NULL THEN

                   BEGIN
                    
                        SELECT ZSTPARA_PARAM_VALOR
                        INTO VL_VIGENCIA_PARA
                        FROM ZSTPARA
                        WHERE ZSTPARA_MAPA_ID = 'VIG_ACCESORIO'
                        AND ZSTPARA_PARAM_ID = SUBSTR(P_DETAIL_CODE,3,2)
                        AND ZSTPARA_PARAM_VALOR = 1;
                                
                   EXCEPTION
                   WHEN NO_DATA_FOUND THEN    
                   VL_VIGENCIA_PARA := NULL;
                   END; 

                   BEGIN
                                                        
                      SELECT  NVL(MAX (TZFACCE_SEC_PIDM),0)+1
                      INTO  LV_TRAN_NUM_2
                      FROM  TZFACCE
                      WHERE TZFACCE_PIDM = P_PIDM;
                                                            
                   EXCEPTION
                   WHEN OTHERS  THEN 
                   LV_TRAN_NUM_2 := 1;
                   END;
                   
                               IF VL_VIGENCIA_PARA IS NULL THEN
                                                               
                                               BEGIN        
                                                                                
                                                    INSERT INTO TZFACCE
                                                    VALUES (P_PIDM,                                 --TZFACCE_PIDM
                                                            LV_TRAN_NUM_2,                          --TZFACCE_SEC_PIDM
                                                            P_PERIODO,                              --TZFACCE_TERM_CODE
                                                            P_DETAIL_CODE,                          --TZFACCE_DETAIL_CODE
                                                            'CAMBIO DE PLAN'||P_CAMBIO,                       --TZFACCE_DESC
                                                            P_MONTO,                                --TZFACCE_AMOUNT
                                                            VL_VENCIMIENTO,                         --TZFACCE_EFFECTIVE_DATE
                                                            'SV2A',                                 --TZFACCE_USER
                                                            SYSDATE,                                --TZFACCE_ACTIVITY_DATE
                                                            0,                                      --TZFACCE_FLAG    
                                                            P_SOLI);
                                                                                
                                               EXCEPTION 
                                               WHEN OTHERS THEN
                                               VL_ERROR:= 'ERROR INSERTAR TZFACCE'||SQLERRM;                           
                                               END;

                               ELSE

                                               BEGIN        
                                                                                        
                                                    INSERT INTO TZFACCE
                                                    VALUES (P_PIDM,                                 --TZFACCE_PIDM
                                                            LV_TRAN_NUM_2,                          --TZFACCE_SEC_PIDM
                                                            P_PERIODO,                              --TZFACCE_TERM_CODE
                                                            P_DETAIL_CODE,                          --TZFACCE_DETAIL_CODE
                                                            'CAMBIO DE PLAN'||P_CAMBIO,                       --TZFACCE_DESC
                                                            P_MONTO,                                --TZFACCE_AMOUNT
                                                            VL_VENCIMIENTO,                         --TZFACCE_EFFECTIVE_DATE
                                                            'REZA',                                 --TZFACCE_USER
                                                            SYSDATE,                                --TZFACCE_ACTIVITY_DATE
                                                            0,                                      --TZFACCE_FLAG    
                                                            P_SOLI);
                                                                                        
                                               EXCEPTION 
                                               WHEN OTHERS THEN
                                               VL_ERROR:= 'ERROR INSERTAR TZFACCE'||SQLERRM;                           
                                               END;
                                     
                               END IF;   
                                            
                ELSE
                            
                               VL_VIGENCIA_PARA := NULL;
                               VL_MES           := NULL;
                                       
                                BEGIN

                                    SELECT ZSTPARA_PARAM_VALOR
                                    INTO VL_VIGENCIA_PARA
                                    FROM ZSTPARA
                                    WHERE ZSTPARA_MAPA_ID = 'VIG_ACCESORIO'
                                    AND ZSTPARA_PARAM_ID = SUBSTR(P_DETAIL_CODE,3,2)
                                    AND ZSTPARA_PARAM_VALOR = 4;
                                                    
                                EXCEPTION
                                WHEN OTHERS THEN    
                                VL_VIGENCIA_PARA := NULL;
                                END;
                                       
                                IF TO_NUMBER(TO_CHAR(C.SORLCUR_START_DATE,'DD')) > 20 THEN 

                                --VL_COMPLE_MES := TO_NUMBER(TO_CHAR(TO_DATE(C.SORLCUR_START_DATE),'MM'))+1;
                                VL_COMPLE_MES := TO_NUMBER((C.MES) + 1);

                                ELSE

                                --VL_COMPLE_MES := TO_NUMBER(TO_CHAR(TO_DATE(C.SORLCUR_START_DATE),'MM'));
                                VL_COMPLE_MES := TO_NUMBER(C.MES);

                                END IF;
            ---------------------------------------------                    
                                BEGIN
                                        
                                    SELECT ZSTPARA_PARAM_VALOR
                                    INTO VL_MES
                                    FROM ZSTPARA
                                    WHERE ZSTPARA_MAPA_ID = 'COMPL_MES'
                                    AND ZSTPARA_PARAM_SEC = VL_COMPLE_MES;
                                    
                                EXCEPTION
                                WHEN OTHERS THEN
                                NULL;    
                                END;
                                                    
                                IF VL_VIGENCIA_PARA IS NOT NULL AND C.CAMPUS = 'UTL' AND C.NIVEL = 'LI' THEN
                                            
                                              IF C.MES IN ('11','12') THEN
                                                VL_VENCIMIENTO := TO_DATE(''||VL_VIGENCIA||'/'||VL_MES_CHAR||'/'||VL_ANO+1||'','DD/MM/YYYY');
                                                --VL_VENCIMIENTO := VL_VIGENCIA||'/'||VL_MES||'/'||(C.ANO+1);
                                                --TO_DATE((CASE VL_MES WHEN '02' THEN '28' ELSE ''||VL_VIGENCIA END)||'/'|| VL_MES||'/'||VL_ANO||'','DD/MM/YYYY');
                                                --TO_DATE(''||VL_VIGENCIA||'/'||VL_MES||'/'||VL_ANO||'','DD/MM/YYYY');
                                              ELSE
                                                VL_VENCIMIENTO := TO_DATE(''||VL_VIGENCIA||'/'||VL_MES_CHAR||'/'||VL_ANO||'','DD/MM/YYYY');
                                                --VL_VENCIMIENTO := VL_VIGENCIA||'/'||VL_MES||'/'||C.ANO;
                                              END IF;
                                                        
                                ELSE
                                        
                                             VL_VENCIMIENTO := VL_VENCIMIENTO;
                                                        
                                END IF;
                                                        
                                BEGIN
                                                                
                                      SELECT  NVL(MAX (TZFACCE_SEC_PIDM),0)+1
                                      INTO  LV_TRAN_NUM_2
                                      FROM  TZFACCE
                                      WHERE TZFACCE_PIDM = P_PIDM;
                                                                    
                                EXCEPTION
                                WHEN OTHERS  THEN 
                                LV_TRAN_NUM_2 := 1;
                                END;
                                                    
                                                            
                                BEGIN        
                                                                
                                    INSERT INTO TZFACCE
                                    VALUES(P_PIDM,                                --TZFACCE_PIDM
                                           LV_TRAN_NUM_2,                         --TZFACCE_SEC_PIDM
                                           P_PERIODO,                             --TZFACCE_TERM_CODE
                                           P_DETAIL_CODE,                         --TZFACCE_DETAIL_CODE
                                           'CAMBIO DE PLAN'||P_CAMBIO,            --TZFACCE_DESC
                                           P_MONTO,                               --TZFACCE_AMOUNT
                                           VL_VENCIMIENTO,                        --TZFACCE_EFFECTIVE_DATE
                                           'REZA',                                --TZFACCE_USER
                                           SYSDATE,                               --TZFACCE_ACTIVITY_DATE
                                           0,                                     --TZFACCE_FLAG 
                                           P_SOLI);
                                EXCEPTION 
                                WHEN OTHERS THEN
                                VL_ERROR:= 'ERROR INSERTAR TZFACCE'||SQLERRM;                       
                                END;                   
                END IF;
                                    
            END IF;
                                
          END LOOP;
                     
        END;
      
      ELSE
         
         BEGIN
           SELECT  NVL(MAX (TZFACCE_SEC_PIDM),0)+1
             INTO  LV_TRAN_NUM_2
             FROM  TZFACCE
            WHERE TZFACCE_PIDM = P_PIDM;                                           
         EXCEPTION
         WHEN OTHERS  THEN 
         LV_TRAN_NUM_2 := 1;
         END;
                                               
         BEGIN        
                                                 
             INSERT INTO TZFACCE
             VALUES(P_PIDM,                         --TZFACCE_PIDM
                    LV_TRAN_NUM_2,                  --TZFACCE_SEC_PIDM
                    P_PERIODO,                      --TZFACCE_TERM_CODE
                    P_DETAIL_CODE,                  --TZFACCE_DETAIL_CODE
                    'CAMBIO DE PLAN'||P_CAMBIO,     --TZFACCE_DESC
                    P_MONTO,                        --TZFACCE_AMOUNT
                    SYSDATE,                        --TZFACCE_EFFECTIVE_DATE
                    'PRIM',                         --TZFACCE_USER
                    SYSDATE,                        --TZFACCE_ACTIVITY_DATE
                    0,                              --TZFACCE_FLAG 
                    P_SOLI);
         EXCEPTION 
         WHEN OTHERS THEN
         VL_ERROR:= 'ERROR INSERTAR TZFACCE'||SQLERRM;                       
         END;             
      END IF;              
    END IF;
  COMMIT;  
  RETURN(VL_ERROR);
 END F_INSERTA_PLAN_CP;

FUNCTION F_CAMBIO_PAQT( P_PIDM              NUMBER,
                        P_SOLI              NUMBER,
                        P_PROGRAMA          VARCHAR2,
                        P_RATE              VARCHAR2,
                        P_JORNADA           VARCHAR2,
                        P_PERIODO           VARCHAR2,
                        P_DSI               NUMBER,
                        P_DESCUENTO         VARCHAR2,
                        P_PAQUETE_OLD       VARCHAR2,
                        P_PAQUETE_NEW       VARCHAR2,
                        P_FECHA_INICIO      DATE, -- FECHA INICIO DE PAQUETE NUEVO
                        P_FECHA_OLD         DATE, --FECHA INICIO DE PAQUETE VIEJO
                        P_COSTO             VARCHAR2 )RETURN VARCHAR2 IS

/*FUNCION CREADA PARA REALIZAR EL CAMBIO DE PARAMETROS DE INSCRIPCION DEL ALUMNO
 AUTOR: JREZAOLI
 ACTUALIZADOA: 04/03/2020
  */


VL_EXIS_SOLI        NUMBER;
VL_ENTRA            NUMBER;
VL_CAMPUS           VARCHAR2(5);
VL_STUDY            NUMBER;
VL_STUDY_ADM        NUMBER;
VL_NIVEL            VARCHAR2(5);
VL_PROGRAMA         VARCHAR2(12);
VL_CODIGO           VARCHAR2(4);
VL_DESCRI           VARCHAR2(40);
VL_EXIS_SGBS        NUMBER;
VL_SEC_SGRSCMT      NUMBER;
VL_MATRICULA        VARCHAR2(11);
VL_ERROR            VARCHAR2(1000):='EXITO';
VL_DESCRIPCION      VARCHAR2(1000);
VL_SEC_SARACMT      NUMBER;
VL_ESTATUS          VARCHAR2(2);
VL_ABCC             NUMBER;
VL_SYSDATE          DATE;

BEGIN

  BEGIN
    SELECT COUNT(*) 
      INTO VL_EXIS_SOLI
      FROM SARADAP
     WHERE SARADAP_PIDM = P_PIDM AND SARADAP_APPL_NO = P_SOLI;  
  END;
  
  BEGIN
    DELETE GORADID
    WHERE GORADID_PIDM = P_PIDM 
    AND GORADID_ADID_CODE IN (SELECT ZSTPARA_PARAM_ID
                                FROM ZSTPARA
                                WHERE ZSTPARA_MAPA_ID = 'BORRAR_ETIQUE'); 
  END;
    
  IF VL_EXIS_SOLI = 0 
    THEN VL_ERROR:= 'Solo se puede realizar el cambio si es Aspirante o Alumno';
  ELSE
  
    BEGIN
       SELECT SORLCUR_CAMP_CODE,
              SORLCUR_LEVL_CODE,
              SORLCUR_PROGRAM
         INTO VL_CAMPUS,
              VL_NIVEL,
              VL_PROGRAMA
         FROM SORLCUR A,
              SARADAP 
        WHERE       1=1
                AND A.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                AND A.SORLCUR_ROLL_IND  = 'N'
                AND A.SORLCUR_SEQNO = (SELECT MAX (A1.SORLCUR_SEQNO)
                                         FROM SORLCUR A1
                                        WHERE       1=1 
                                                AND A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                                AND A1.SORLCUR_ROLL_IND = A.SORLCUR_ROLL_IND
                                                AND A1.SORLCUR_KEY_SEQNO = A.SORLCUR_KEY_SEQNO)
               AND SARADAP_PIDM = A.SORLCUR_PIDM  
               AND SARADAP_APPL_NO = A.SORLCUR_KEY_SEQNO
               AND SARADAP_APPL_NO = P_SOLI
               AND SARADAP_PIDM = P_PIDM;
               
    
    EXCEPTION
    WHEN OTHERS THEN                                                 
    VL_CAMPUS:=NULL;
    VL_STUDY_ADM:=NULL;
    VL_NIVEL:=NULL;
    END;
    
    BEGIN
    
        SELECT SORLCUR_KEY_SEQNO
          INTO VL_STUDY
          FROM SORLCUR A
         WHERE      A.SORLCUR_PIDM      = P_PIDM
                AND A.SORLCUR_APPL_KEY_SEQNO = P_SOLI
                AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                AND A.SORLCUR_ROLL_IND  = 'Y'
                AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                AND A.SORLCUR_SEQNO     IN ( SELECT MAX (A1.SORLCUR_SEQNO)
                                               FROM SORLCUR A1
                                              WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                    AND A1.SORLCUR_APPL_KEY_SEQNO = A.SORLCUR_APPL_KEY_SEQNO 
                                                    AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                                    AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                                    AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE);
             
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        BEGIN
        
            SELECT SORLCUR_KEY_SEQNO+1
              INTO VL_STUDY
              FROM SORLCUR A
             WHERE      A.SORLCUR_PIDM      = P_PIDM
                    AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                    AND A.SORLCUR_KEY_SEQNO     IN ( SELECT MAX (A1.SORLCUR_KEY_SEQNO)
                                                   FROM SORLCUR A1
                                                  WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM 
                                                        AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE);
        EXCEPTION
        WHEN OTHERS THEN
        VL_STUDY:=1;      
        END;
    END;
    
    BEGIN
       SELECT SGBSTDN_STYP_CODE
         INTO VL_ESTATUS
         FROM SGBSTDN A
        WHERE     1 = 1
              AND A.SGBSTDN_PIDM = P_PIDM
              AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                               FROM SGBSTDN
                                               WHERE SGBSTDN_PIDM = A.SGBSTDN_PIDM);
    EXCEPTION
    WHEN OTHERS THEN
    VL_ESTATUS := 'N';
    END;
    
    BEGIN
     SELECT ZSTPARA_PARAM_VALOR
       INTO VL_ABCC
       FROM ZSTPARA
      WHERE 1 = 1
        AND ZSTPARA_MAPA_ID = 'PQ_RANGOTIEMPO';
    EXCEPTION
    WHEN OTHERS THEN
    VL_ABCC:=0;    
    END;
     
    IF VL_ESTATUS NOT IN ('N','R','F') 
       THEN VL_ERROR:= 'El alumno no es Nuevo Ingreso'; 
    ELSE   
     
      IF TRUNC(SYSDATE) <= P_FECHA_OLD THEN
      
       VL_SYSDATE:= P_FECHA_OLD;
      
      ELSE 
      
      VL_SYSDATE:= TRUNC(SYSDATE);
      END IF;  
    
    
      IF (P_FECHA_OLD+VL_ABCC) < TRUNC(VL_SYSDATE)        
        THEN VL_ERROR:= 'No se puede realizar cambio de paquete... '||CHR(10)||'Está fuera del rango de tiempo de '||VL_ABCC||' días, a partir de la fecha del '||TO_CHAR(P_FECHA_OLD,'DD/MM/YYYY')||CHR(10)||'Fecha limite de cambio: '||TO_CHAR((P_FECHA_OLD+VL_ABCC),'DD/MM/YYYY');
      ELSE
       
          BEGIN
          
           UPDATE SARADAP
              SET SARADAP_RATE_CODE = P_RATE
            WHERE       1=1
                   AND SARADAP_APPL_NO = P_SOLI
                   AND SARADAP_PIDM = P_PIDM;
          END;
          
          BEGIN
          
            UPDATE SORLCUR A
               SET A.SORLCUR_APPL_KEY_SEQNO = P_SOLI,
                   A.SORLCUR_RATE_CODE      = P_RATE,
                   A.SORLCUR_USER_ID_UPDATE = USER,
                   A.SORLCUR_START_DATE     = P_FECHA_INICIO,
                   A.SORLCUR_SITE_CODE      = P_COSTO
             WHERE      1=1
                    AND A.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                    AND A.SORLCUR_ROLL_IND  = 'N'
                    AND A.SORLCUR_SEQNO = ( SELECT MAX (A1.SORLCUR_SEQNO)
                                              FROM SORLCUR A1
                                             WHERE      1=1 
                                                    AND A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                    AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                                    AND A1.SORLCUR_ROLL_IND = A.SORLCUR_ROLL_IND
                                                    AND A1.SORLCUR_KEY_SEQNO = A.SORLCUR_KEY_SEQNO)  
                    AND A.SORLCUR_KEY_SEQNO = P_SOLI
                    AND A.SORLCUR_PIDM = P_PIDM;
          
          END;
        
          BEGIN
            UPDATE SORLCUR A
               SET A.SORLCUR_APPL_KEY_SEQNO = P_SOLI,
                   A.SORLCUR_RATE_CODE      = P_RATE,
                   A.SORLCUR_USER_ID_UPDATE = USER,
                   A.SORLCUR_START_DATE     = P_FECHA_INICIO
             WHERE      A.SORLCUR_PIDM      = P_PIDM
                    AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                    AND A.SORLCUR_ROLL_IND  = 'Y'
                    AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                    AND (   A.SORLCUR_APPL_KEY_SEQNO = P_SOLI 
                         OR A.SORLCUR_APPL_KEY_SEQNO IS NULL) 
                    AND A.SORLCUR_SEQNO     IN ( SELECT MAX (A1.SORLCUR_SEQNO)
                                                   FROM SORLCUR A1
                                                  WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                                        AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                                        AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                                        AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                                        AND (   A1.SORLCUR_APPL_KEY_SEQNO = P_SOLI
                                                             OR A.SORLCUR_APPL_KEY_SEQNO IS NULL));
                 
          EXCEPTION
          WHEN OTHERS THEN
          VL_ERROR:='Error al actualizar SORLCUR = '||SQLERRM;      
          END;
          
          BEGIN
              UPDATE TZTDMTO
                 SET TZTDMTO_IND           = 0
               WHERE    TZTDMTO_PIDM       = P_PIDM
                    AND TZTDMTO_TERM_CODE  = P_PERIODO
                    AND TZTDMTO_PROGRAMA   = P_PROGRAMA
                    AND TZTDMTO_STUDY_PATH = VL_STUDY; 
                   
          END;
          
          BEGIN
          
            BEGIN
              UPDATE TZTDMTO
                 SET TZTDMTO_MONTO         = P_DSI,
                     TZTDMTO_IND           = 1,
                     TZTDMTO_ACTIVITY_DATE = SYSDATE
               WHERE    TZTDMTO_PIDM       = P_PIDM
                    AND TZTDMTO_TERM_CODE  = P_PERIODO
                    AND TZTDMTO_PROGRAMA   = P_PROGRAMA
                    AND TZTDMTO_STUDY_PATH = VL_STUDY; 
                   
            END;
             
            IF SQL%ROWCOUNT = 0 THEN
          
               IF    VL_NIVEL = 'MA' THEN VL_CODIGO:= 'GB';
               ELSIF VL_NIVEL = 'MS' THEN VL_CODIGO:= 'GH';
               ELSIF VL_NIVEL = 'LI' THEN VL_CODIGO:= 'GA';
               ELSIF VL_NIVEL = 'DO' THEN VL_CODIGO:= 'GD';
               END IF;
               
               BEGIN
               
                    SELECT TBBDETC_DETAIL_CODE,
                           TBBDETC_DESC
                      INTO VL_CODIGO,
                           VL_DESCRI
                      FROM TBBDETC
                     WHERE      1=1
                            AND TBBDETC_DETAIL_CODE = SUBSTR(P_PERIODO,1,2)||VL_CODIGO;
               EXCEPTION
               WHEN OTHERS THEN
               VL_ERROR:= 'Error al calcular codigo DSI'||SQLERRM;             
               END;
            
               BEGIN
                    SELECT SPRIDEN_ID
                      INTO VL_MATRICULA
                      FROM SPRIDEN
                     WHERE SPRIDEN_CHANGE_IND IS NULL
                     AND SPRIDEN_PIDM = P_PIDM;
                      
               EXCEPTION
               WHEN OTHERS THEN
               VL_MATRICULA:= NULL;
               END;
            
               BEGIN
                    
                    INSERT 
                    INTO TZTDMTO 
                    VALUES(VL_MATRICULA, 
                    P_PIDM, 
                    VL_CAMPUS,
                    VL_NIVEL, 
                    VL_PROGRAMA, 
                    P_PERIODO,
                    VL_CODIGO, 
                    NULL, 
                    P_DSI, 
                    VL_STUDY, 
                    1, 
                    SYSDATE, 
                    VL_DESCRI
                    , NULL ); -- Nueva Columna
                        
               EXCEPTION
               WHEN OTHERS THEN
               VL_ERROR:= 'ERROR AL INSERTAR EN TZTDMTO  '||SQLERRM;    
               END;
                       
            END IF;
             
          END;
          
          BEGIN
          
             BEGIN
                DELETE TBBESTU
                 WHERE TBBESTU_PIDM = P_PIDM AND TBBESTU_TERM_CODE = P_PERIODO;
             END;
                 
             BEGIN

                INSERT INTO TBBESTU 
                VALUES(P_DESCUENTO,
                       P_PIDM,
                       P_PERIODO,
                       SYSDATE,
                       NULL,
                       'Y',
                       NULL,      
                       USER,
                       1,
                       NULL,
                       NULL,
                       NULL,
                      'CPQT',
                       NULL  
                            );
                                                                                    
             EXCEPTION
             WHEN OTHERS THEN               
             VL_ERROR:= 'Error al insertar Descuento'||SQLERRM;               
             END;      
                 
          END;
          
          BEGIN
          
            BEGIN
              
                DELETE SGRSATT 
                 WHERE     SGRSATT_PIDM = P_PIDM
                       AND SGRSATT_STSP_KEY_SEQUENCE = VL_STUDY
                       AND REGEXP_LIKE (SGRSATT_ATTS_CODE, '^[0-9]')
                       AND SUBSTR (SGRSATT_TERM_CODE_EFF, 5, 1) NOT IN (8,9)
                       AND SGRSATT_TERM_CODE_EFF = P_PERIODO;
              
            END;
             
            BEGIN
                
                  INSERT INTO SGRSATT 
                              (SGRSATT_PIDM, 
                              SGRSATT_TERM_CODE_EFF, 
                              SGRSATT_ATTS_CODE, 
                              SGRSATT_ACTIVITY_DATE, 
                              SGRSATT_STSP_KEY_SEQUENCE,
                              SGRSATT_USER_ID)
                  VALUES (P_PIDM, 
                          P_PERIODO, 
                          P_JORNADA, 
                          SYSDATE,
                          VL_STUDY,
                          USER); 
                          
            EXCEPTION
            WHEN OTHERS THEN
            VL_ERROR:= 'Error al insertar jornada = '||SQLERRM;    
            END;
      
          END;
          
          BEGIN
            SELECT COUNT(*)
              INTO VL_EXIS_SGBS
              FROM SGBSTDN
             WHERE SGBSTDN_PIDM = P_PIDM
             AND SGBSTDN_PROGRAM_1 = VL_PROGRAMA
             AND SGBSTDN_TERM_CODE_EFF = P_PERIODO;
          
          END;
          
          BEGIN
            SELECT NVL(MAX(SGRSCMT_SEQ_NO),0)+1
              INTO VL_SEC_SGRSCMT
              FROM SGRSCMT
             WHERE      SGRSCMT_PIDM  = P_PIDM
                    AND SGRSCMT_TERM_CODE = P_PERIODO;
          END;
          
          IF VL_EXIS_SGBS > 0 THEN
            
            BEGIN
               INSERT 
                 INTO SGBSTDB
                   SELECT N.*,P_FECHA_OLD, VL_SEC_SGRSCMT, VL_STUDY
                   FROM SGBSTDN N 
                   WHERE N.SGBSTDN_PIDM = P_PIDM 
                   AND N.SGBSTDN_TERM_CODE_EFF = P_PERIODO;
            
            EXCEPTION
            WHEN OTHERS THEN
            VL_ERROR:= 'Error al insertar en SGBSTDB = '||SQLERRM;       
            END;
          
            BEGIN
            
                UPDATE SGBSTDN
                   SET SGBSTDN_RATE_CODE = P_RATE
                 WHERE SGBSTDN_PIDM = P_PIDM
                 AND SGBSTDN_PROGRAM_1 = VL_PROGRAMA
                 AND SGBSTDN_TERM_CODE_EFF = P_PERIODO;
            
            EXCEPTION
            WHEN OTHERS THEN
            VL_ERROR:= 'Error al actualizar en SGBSTDN = '||SQLERRM;       
            END;     
            
            
          END IF;
          
          BEGIN
          
            BEGIN
              SELECT MAX(SARACMT_SEQNO)+1
                INTO VL_SEC_SARACMT
                FROM SARACMT
               WHERE      SARACMT_PIDM = P_PIDM 
                      AND SARACMT_APPL_NO = P_SOLI;  
              
            EXCEPTION
            WHEN OTHERS THEN
            VL_SEC_SARACMT:=1;
            END;
      
            BEGIN
            
                 INSERT 
                   INTO  SARACMT
                        (SARACMT_PIDM, 
                         SARACMT_TERM_CODE, 
                         SARACMT_APPL_NO, 
                         SARACMT_SEQNO, 
                         SARACMT_COMMENT_TEXT, 
                         SARACMT_ORIG_CODE, 
                         SARACMT_ACTIVITY_DATE, 
                         SARACMT_USER_ID, 
                         SARACMT_DATA_ORIGIN)
                 VALUES
                        (P_PIDM, 
                        P_PERIODO, 
                        P_SOLI, 
                        VL_SEC_SARACMT, 
                        P_PAQUETE_NEW, 
                        'PAQT', 
                        SYSDATE, 
                        'SV2', 
                        'CPAQT');


            EXCEPTION
            WHEN OTHERS THEN
            VL_ERROR:= 'Error al insertar en SARACMT = '||SQLERRM;       
            END;
            
            VL_DESCRIPCION := 'PAQUETE ANT = '||P_PAQUETE_OLD||', PAQUETE NUEVO = '|| P_PAQUETE_NEW;
          
            BEGIN

                 INSERT 
                   INTO SGRSCMT 
                    (SGRSCMT_PIDM,
                     SGRSCMT_SEQ_NO,
                     SGRSCMT_TERM_CODE,
                     SGRSCMT_COMMENT_TEXT,
                     SGRSCMT_ACTIVITY_DATE,
                     SGRSCMT_DATA_ORIGIN,
                     SGRSCMT_USER_ID,
                     SGRSCMT_VPDI_CODE)
                 VALUES (
                        P_PIDM,
                        VL_SEC_SGRSCMT, 
                        P_PERIODO,
                        VL_DESCRIPCION,
                        SYSDATE,
                        'CPAQT',
                        USER,
                        VL_STUDY );
                 
            EXCEPTION
            WHEN OTHERS THEN 
            NULL;            
            END;    
          
          END;
      
      END IF;
      
    END IF;
    
  END IF;
  
--  VL_ERROR:=('error pinche fidel = '||TO_DATE(P_FECHA_INICIO,'RRRR/MM/DD'));
  
  IF VL_ERROR = 'EXITO' THEN
   COMMIT;
  ELSE
   ROLLBACK;
  END IF;
  
  DBMS_OUTPUT.PUT_LINE(VL_ERROR);
  
  RETURN(VL_ERROR);
  

END F_CAMBIO_PAQT;

--
--
  FUNCTION f_solic_servi (p_pidm NUMBER, p_solicitud NUMBER) RETURN PKG_ACTUALIZA_DATOS.cursor_out_solic_servi  --FER V1.15/04/2020
           AS
                c_out_solic_servi PKG_ACTUALIZA_DATOS.cursor_out_solic_servi;

  BEGIN 
       open c_out_solic_servi
         FOR SELECT DISTINCT 
                svrsvpr_protocol_seq_no SOLICITUD,
                spriden_id MATRICULA,
                svrsvpr_srvc_code COD_SERV,
                (SELECT DISTINCT svvsrvc_desc FROM svvsrvc WHERE 1=1 AND svvsrvc_code = svrsvpr_srvc_code) DESCRIP_SOLIC,
                svrsvpr_protocol_amount COSTO_SOLIC,
                (SELECT svvsrvs_desc FROM svvsrvs WHERE 1=1 AND svvsrvs_code = svrsvpr_srvs_code) ESTATUS_SOLIC,
                (SELECT stvwsso_desc FROM stvwsso WHERE 1=1 AND stvwsso_code = svrsvpr_wsso_code ) TIPO_ENTREGA,
                (SELECT stvwsso_chrg FROM stvwsso WHERE 1=1 AND stvwsso_code = svrsvpr_wsso_code ) COSTO_ENTREGA,
                svrsvpr_accd_tran_number TRANSACCION,
                svrsvpr_user_id USUARIO,
                svrsvpr_activity_date ACTIVIDAD
             FROM svrsvpr, spriden
             WHERE 1=1
             AND svrsvpr_pidm = spriden_pidm
             AND spriden_change_ind IS NULL
             --AND spriden_id = '010001015'
             AND svrsvpr_pidm = p_pidm
             AND svrsvpr_protocol_seq_no = P_SOLICITUD;

       RETURN (c_out_solic_servi);
       
  END;
  
  
  
FUNCTION f_bitacora_sgastdn (p_pidm NUMBER, p_come VARCHAR2, p_usuario VARCHAR2) RETURN VARCHAR2

    IS
   
l_error VARCHAR2 (1000):= 'EXITO';
l_max_periodo VARCHAR2 (20):= NULL;
l_seq_sgrscmt NUMBER := NULL;


BEGIN

     
          IF l_error = 'EXITO' then
                             
              l_max_periodo := NULL;
                                         
              BEGIN
             
                  SELECT DISTINCT sgbstdn_term_code_eff MAX_PERIODO
                  INTO l_max_periodo
                  FROM sgbstdn A, spriden B, sorlcur C
                  WHERE 1=1
                  AND a.sgbstdn_pidm = b.spriden_pidm
                  AND sorlcur_pidm = sgbstdn_pidm
                  AND b.spriden_change_ind IS NULL
                  AND c. sorlcur_lmod_code =  'LEARNER'
  --                AND spriden_id = '010215013'
                  AND sorlcur_pidm = p_pidm
                  AND a.sgbstdn_term_code_eff = (SELECT MAX (A1.sgbstdn_term_code_eff)
                                                 FROM sgbstdn A1
                                                 WHERE 1=1
                                                 AND a.sgbstdn_pidm= a1.sgbstdn_pidm)
                  AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
                                         FROM sorlcur c1
                                         WHERE 1=1
                                         AND c.sorlcur_pidm= c1.sorlcur_pidm
                                         AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code);
                   

              EXCEPTION WHEN OTHERS THEN
                  dbms_output.put_line ('ERROR AL OBTENER MAXIMO PERIODO '||sqlerrm);
                  l_error:='ERROR AL OBTENER MAXIMO PERIODO '||sqlerrm;
                   
              END;
             
                  l_seq_sgrscmt := NULL;                      
             
                  BEGIN
                 
                      SELECT NVL(MAX(sgrscmt_seq_no),0)+1
                      INTO l_seq_sgrscmt
                      FROM sgrscmt
                      WHERE 1=1
                      AND sgrscmt_pidm  = p_pidm
                      AND sgrscmt_term_code = l_max_periodo;
                     
                  EXCEPTION WHEN OTHERS THEN
                    dbms_output.put_line ('ERROR AL OBTENER SECUENCIA MAXIMA'||sqlerrm);
                    l_error:='ERROR AL OBTENER SECUENCIA MAXIMA'||sqlerrm;
                   
                  END;
                 
                      BEGIN
                     
                          INSERT INTO sgrscmt
                          VALUES
                            (p_pidm,
                             l_seq_sgrscmt,
                             l_max_periodo,
                             p_come,
                             SYSDATE,
                             NULL,
                             NULL,
                             p_usuario,
                             'Bitacora',
                             NULL);
                                       
                      EXCEPTION
                      WHEN OTHERS THEN
                             
                          DBMS_OUTPUT.PUT_LINE('ERROR AL INSERTAR BITACORA');
                          l_error:=('ERROR AL INSERTAR BITACORA '||sqlerrm||' PERIODO '||l_max_periodo);

                      END;
             
          END IF;        

  COMMIT;

  RETURN (l_error);
 
END;

FUNCTION F_ESTATUS (P_PIDM IN NUMBER)RETURN VARCHAR2 IS

/*
FUNCION PARA DETERMINAR SI ES POSIBLE REALIZAR EL CAMBIO DE PAQUETE
JREZAOLI    23/04/2020
 */

VL_ERROR            VARCHAR2(500);
VL_SGBSTDN          NUMBER;
VL_ABCC             NUMBER;
VL_FECHA_INICIO     DATE;
VL_SYSDATE          DATE;


 BEGIN

     BEGIN
        SELECT COUNT(*)
          INTO VL_SGBSTDN
          FROM SORLCUR A
         WHERE     A.SORLCUR_PIDM      = P_PIDM
               AND A.SORLCUR_LMOD_CODE = 'LEARNER'
               AND A.SORLCUR_ROLL_IND  = 'Y'
               AND A.SORLCUR_CACT_CODE = 'ACTIVE'
               AND A.SORLCUR_SEQNO IN ( SELECT MAX (A1.SORLCUR_SEQNO)
                                          FROM SORLCUR A1
                                         WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM 
                                               AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                               AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                               AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE);
     END;
     
     IF VL_SGBSTDN = 0 THEN
     
      VL_ERROR:= 'INACTIVO';
      
     ELSE
     
        BEGIN
         SELECT ZSTPARA_PARAM_VALOR
           INTO VL_ABCC
           FROM ZSTPARA
          WHERE 1 = 1
            AND ZSTPARA_MAPA_ID = 'PQ_RANGOTIEMPO';
        EXCEPTION
        WHEN OTHERS THEN
        VL_ABCC:=0;    
        END;
        
        BEGIN
            SELECT SORLCUR_START_DATE
              INTO VL_FECHA_INICIO
              FROM SORLCUR A
             WHERE     A.SORLCUR_PIDM      = P_PIDM
                   AND A.SORLCUR_LMOD_CODE = 'LEARNER'
                   AND A.SORLCUR_ROLL_IND  = 'Y'
                   AND A.SORLCUR_CACT_CODE = 'ACTIVE'
                   AND A.SORLCUR_SEQNO IN ( SELECT MAX (A1.SORLCUR_SEQNO)
                                              FROM SORLCUR A1
                                             WHERE     A1.SORLCUR_PIDM = A.SORLCUR_PIDM 
                                                   AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                                   AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                                   AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE);
        EXCEPTION
        WHEN OTHERS THEN
        VL_FECHA_INICIO:='01/01/1990';                                        
        END;
        
        DBMS_OUTPUT.PUT_LINE('VL_FECHA_INICIO = '||VL_FECHA_INICIO||' = '||vl_abcc);
        
        IF TRUNC(SYSDATE) <= VL_FECHA_INICIO THEN
      
           VL_SYSDATE:= VL_FECHA_INICIO;
          
        ELSE 
          
          VL_SYSDATE:= TRUNC(SYSDATE);
        END IF;  
        
        DBMS_OUTPUT.PUT_LINE('VL_SYSDATE = '||VL_SYSDATE||' = '||(VL_FECHA_INICIO+VL_ABCC));
        
        IF (VL_FECHA_INICIO+VL_ABCC) < TRUNC(VL_SYSDATE) THEN 
     
            VL_ERROR:= 'No se puede realizar cambio de paquete... '||CHR(10)||'Está fuera del rango de tiempo de '||VL_ABCC||' días, a partir de la fecha del '||TO_CHAR(VL_FECHA_INICIO,'DD/MM/YYYY')||CHR(10)||'Fecha limite de cambio: '||TO_CHAR((VL_FECHA_INICIO+VL_ABCC),'DD/MM/YYYY');
     
        ELSE
        
            VL_ERROR:= 'EXITO';
        
        END IF;
          
     END IF;
 
    RETURN(VL_ERROR);
 
 END F_ESTATUS;
 
 FUNCTION F_CARTERA_C_PQT (P_PIDM NUMBER,P_FECHA DATE)RETURN VARCHAR2 IS
                            
/*                            
 Funcion para cancelar cartera en TVAAREV e insertar nueva cartera con nuevos parametros
 a solicitud de CAMBIO DE PAQUETE JREZAOLI 14/04/2020
 */                           

VTRAN_MAX       NUMBER;
VL_MATRICULA    VARCHAR2(11);
VL_ERROR        VARCHAR2(500):= NULL;
VL_PERIODO      VARCHAR2(10);
VL_ABCC         NUMBER;
VL_DESCR        VARCHAR2(40);
VL_CODIGO       VARCHAR2(5);

 BEGIN
 
   BEGIN    
     SELECT MAX(DISTINCT TBRACCD_TERM_CODE)
       INTO VL_PERIODO
       FROM TBRACCD A,TBBDETC
      WHERE     A.TBRACCD_PIDM = P_PIDM
            AND A.TBRACCD_FEED_DATE = P_FECHA
            AND A.TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
            AND (    A.TBRACCD_CREATE_SOURCE LIKE 'TZFEDCA%'
                 AND TBBDETC_DCAT_CODE = 'COL' 
                 OR SUBSTR(A.TBRACCD_DETAIL_CODE,3,2) IN ('M3','XH','X2','QI','QK','QG', 'TF', 'TG', 'TH')
                 AND LAST_DAY(TRUNC(A.TBRACCD_EFFECTIVE_DATE)) >= LAST_DAY(P_FECHA)    
                 ) 
            AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
            AND A.TBRACCD_USER != 'MIGRA_D';
   EXCEPTION
   WHEN OTHERS THEN
   VL_PERIODO:= NULL;     
   END;
    DBMS_OUTPUT.PUT_LINE('cambio 1 = '||VL_PERIODO);   
   BEGIN
     SELECT ZSTPARA_PARAM_VALOR
       INTO VL_ABCC
       FROM ZSTPARA
      WHERE 1 = 1
        AND ZSTPARA_MAPA_ID = 'PQ_RANGOTIEMPO';
   EXCEPTION
   WHEN OTHERS THEN
   VL_ABCC:=0;    
   END;
   
   BEGIN
         
          SELECT SPRIDEN_ID
          INTO VL_MATRICULA
          FROM SPRIDEN
          WHERE SPRIDEN_PIDM = P_PIDM
          AND SPRIDEN_CHANGE_IND IS NULL
          ;
     EXCEPTION 
     WHEN OTHERS THEN
     VL_ERROR:= 'ERROR AL RECUPERAR MATRICULA '||SQLERRM;     
     END;
     
   DBMS_OUTPUT.PUT_LINE('cambio 2 = '||VL_ABCC);
   IF VL_PERIODO IS NOT NULL THEN
    
       IF (P_FECHA+VL_ABCC) >= TRUNC(SYSDATE) THEN       
         
         IF VL_ERROR IS NULL THEN

             BEGIN
           
                UPDATE TZDOCTR 
                SET TZDOCTR_IND = 0,
                    TZDOCTR_OBSERVACIONES = 'Cambio de paquete'
                WHERE TZDOCTR_PIDM = P_PIDM
                AND TZDOCTR_START_DATE = P_FECHA
                AND TZDOCTR_TIPO_PROC != 'AUME';
                
             END;

            VL_ERROR:= 'NO EXISTEN TRANSACCIONES A CANCELAR';
            
            DBMS_OUTPUT.PUT_LINE('INICIA '||P_FECHA);

             BEGIN

                FOR PARCIALIDADES  IN (
                    
                                 SELECT  TBRACCD_PIDM, 
                                         TBRACCD_TRAN_NUMBER,
                                         TBRACCD_TERM_CODE,
                                         TBRACCD_DETAIL_CODE,
                                         TBRACCD_AMOUNT,
                                         TBRACCD_BALANCE,
                                         TBRACCD_DESC,
                                         TBRACCD_USER,
                                         TBRACCD_ENTRY_DATE,
                                         TBRACCD_EFFECTIVE_DATE,
                                         TBRACCD_SRCE_CODE,
                                         TBRACCD_ACCT_FEED_IND,
                                         TBRACCD_ACTIVITY_DATE,
                                         TBRACCD_SESSION_NUMBER,
                                         TBRACCD_SURROGATE_ID,
                                         TBRACCD_VERSION,
                                         TBRACCD_STSP_KEY_SEQUENCE,
                                         TBRACCD_PERIOD,
                                         TBRACCD_FEED_DATE,
                                         TBRACCD_RECEIPT_NUMBER,
                                         TBBDETC_TYPE_IND,
                                         (SELECT ZSTPARA_PARAM_VALOR
                                          FROM ZSTPARA
                                          WHERE ZSTPARA_MAPA_ID = 'CANC_DEC40'
                                          AND ZSTPARA_PARAM_ID = SUBSTR(A.TBRACCD_DETAIL_CODE,3,2))CANCELACION
                                FROM TBRACCD A,TBBDETC
                                WHERE A.TBRACCD_PIDM = P_PIDM
                                AND A.TBRACCD_FEED_DATE = P_FECHA
                                AND A.TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                AND (   A.TBRACCD_CREATE_SOURCE LIKE 'TZFEDCA%'
                                     AND TBBDETC_DCAT_CODE = 'COL' 
                                     OR SUBSTR(A.TBRACCD_DETAIL_CODE,3,2) IN ('M3','XH','X2','QI','QK','QG', 'TF', 'TG', 'TH')
                                     AND LAST_DAY(TRUNC(A.TBRACCD_EFFECTIVE_DATE)) >= LAST_DAY(P_FECHA)
                                     ) 
                                AND A.TBRACCD_DOCUMENT_NUMBER IS NULL
                                AND A.TBRACCD_USER != 'MIGRA_D'
                                
                                                                                       
                )LOOP

                  DBMS_OUTPUT.PUT_LINE('1');  

                  VL_ERROR      := NULL;   
                  VTRAN_MAX     := NULL;      
                  VL_DESCR      := NULL;  
                  VL_CODIGO     := NULL;  
                  
                  IF PARCIALIDADES.CANCELACION IS NOT NULL THEN
                     
                    VL_CODIGO:= SUBSTR(PARCIALIDADES.TBRACCD_DETAIL_CODE,1,2)||PARCIALIDADES.CANCELACION;
                    
                     BEGIN   
                        SELECT TBBDETC_DESC
                          INTO VL_DESCR
                          FROM TBBDETC
                         WHERE TBBDETC_DETAIL_CODE = SUBSTR(PARCIALIDADES.TBRACCD_DETAIL_CODE,1,2)||PARCIALIDADES.CANCELACION;
                     EXCEPTION
                     WHEN OTHERS THEN
                     VL_DESCR:=NULL;    
                     END;
                         
                  ELSE
                        
                     VL_CODIGO:= SUBSTR(PARCIALIDADES.TBRACCD_DETAIL_CODE,1,2)||'EZ';
                      
                      BEGIN   
                         SELECT TBBDETC_DESC
                           INTO VL_DESCR
                           FROM TBBDETC
                          WHERE TBBDETC_DETAIL_CODE = SUBSTR(PARCIALIDADES.TBRACCD_DETAIL_CODE,1,2)||'EZ';
                      EXCEPTION
                      WHEN OTHERS THEN
                      VL_DESCR:=NULL;    
                      END;
                      
                  END IF;
                  
                  IF PARCIALIDADES.TBBDETC_TYPE_IND = 'C' THEN
                  
                      BEGIN
                        UPDATE TBRACCD
                           SET TBRACCD_TRAN_NUMBER_PAID = NULL
                         WHERE     TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM
                               AND TBRACCD_TRAN_NUMBER_PAID = PARCIALIDADES.TBRACCD_TRAN_NUMBER;
                      END;
                                        
                      BEGIN
                                      
                        SELECT MAX(TBRACCD_TRAN_NUMBER)+1 
                        INTO  VTRAN_MAX
                        FROM TBRACCD 
                        WHERE TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM ;
                                      
                      END;
                                        
                     PKG_FINANZAS.P_DESAPLICA_PAGOS (PARCIALIDADES.TBRACCD_PIDM, PARCIALIDADES.TBRACCD_TRAN_NUMBER);
                     
                      BEGIN            

                            INSERT 
                            INTO TBRACCD 
                                 (TBRACCD_PIDM, 
                                  TBRACCD_TRAN_NUMBER,
                                  TBRACCD_TERM_CODE,
                                  TBRACCD_DETAIL_CODE,
                                  TBRACCD_AMOUNT,
                                  TBRACCD_BALANCE,
                                  TBRACCD_DESC,
                                  TBRACCD_USER,
                                  TBRACCD_ENTRY_DATE,
                                  TBRACCD_EFFECTIVE_DATE,
                                  TBRACCD_TRANS_DATE,
                                  TBRACCD_SRCE_CODE,
                                  TBRACCD_ACCT_FEED_IND,
                                  TBRACCD_ACTIVITY_DATE,
                                  TBRACCD_SESSION_NUMBER,
                                  TBRACCD_SURROGATE_ID,
                                  TBRACCD_VERSION,
                                  TBRACCD_TRAN_NUMBER_PAID,
                                  TBRACCD_FEED_DATE,
                                  TBRACCD_STSP_KEY_SEQUENCE,
                                  TBRACCD_DATA_ORIGIN, 
                                  TBRACCD_PERIOD,
                                  TBRACCD_RECEIPT_NUMBER  )
                             VALUES(PARCIALIDADES.TBRACCD_PIDM, 
                                    VTRAN_MAX,
                                    PARCIALIDADES.TBRACCD_TERM_CODE ,
                                    VL_CODIGO, 
                                    PARCIALIDADES.TBRACCD_AMOUNT, 
                                    PARCIALIDADES.TBRACCD_AMOUNT*-1 , 
                                    VL_DESCR, 
                                    USER,
                                    SYSDATE,
                                    SYSDATE,
                                    SYSDATE,
                                    PARCIALIDADES.TBRACCD_SRCE_CODE,
                                    PARCIALIDADES.TBRACCD_ACCT_FEED_IND,
                                    PARCIALIDADES.TBRACCD_ACTIVITY_DATE,
                                    0,
                                    NULL,
                                    NULL,
                                    PARCIALIDADES.TBRACCD_TRAN_NUMBER,
                                    PARCIALIDADES.TBRACCD_FEED_DATE, 
                                    PARCIALIDADES.TBRACCD_STSP_KEY_SEQUENCE, 
                                    'CAMPQT',
                                    PARCIALIDADES.TBRACCD_PERIOD,
                                    PARCIALIDADES.TBRACCD_RECEIPT_NUMBER  );
                          
                      END;
                                
                      BEGIN
                                  
                           INSERT 
                           INTO TBRAPPL 
                           VALUES (
                                    PARCIALIDADES.TBRACCD_PIDM,               --TBRAPPL_PIDM
                                    VTRAN_MAX,               --TBRAPPL_PAY_TRAN_NUMBER
                                    PARCIALIDADES.TBRACCD_TRAN_NUMBER,               --TBRAPPL_CHG_TRAN_NUMBER
                                    PARCIALIDADES.TBRACCD_AMOUNT ,              --TBRAPPL_AMOUNT
                                    NULL,             --TBRAPPL_DIRECT_PAY_IND
                                    NULL,              --TBRAPPL_REAPPL_IND
                                    USER,              --TBRAPPL_USER
                                    'Y',              --TBRAPPL_ACCT_FEED_IND
                                    SYSDATE,              --TBRAPPL_ACTIVITY_DATE
                                    NULL,              --TBRAPPL_FEED_DATE
                                    'Y',              --TBRAPPL_FEED_DOC_CODE
                                    NULL,              --TBRAPPL_CPDT_TRAN_NUMBER
                                    NULL,                 --TBRAPPL_DIRECT_PAY_TYPE
                                    NULL,        ---TBRAPPL_INV_NUMBER_PAID
                                    NULL,            --TBRAPPL_SURROGATE_ID
                                    NULL,             --TBRAPPL_VERSION
                                    NULL,             --TBRAPPL_USER_ID
                                    'CAMPQT',          --TBRAPPL_DATA_ORIGIN
                                    NULL                ---TBRAPPL_VPDI_CODE
                                    );
                                    
                                    DBMS_OUTPUT.PUT_LINE('4');
                      EXCEPTION
                      WHEN OTHERS THEN
                      VL_ERROR :=' Errror al insertar tbrappl>>  ' || SQLERRM ;
                      END;

                      BEGIN
                                  
                             UPDATE TBRACCD
                             SET TBRACCD_BALANCE = 0,
                                 TBRACCD_DOCUMENT_NUMBER = 'CAMPQT',
                                 TBRACCD_ACTIVITY_DATE = SYSDATE
                             WHERE TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM
                             AND TBRACCD_TRAN_NUMBER = VTRAN_MAX;
                                         
                      EXCEPTION
                      WHEN OTHERS THEN
                      VL_ERROR :=' Errror al actualizar saldo Pago>>  ' || SQLERRM ;
                      END;
                                     
                      BEGIN
                               UPDATE TBRACCD
                               SET TBRACCD_BALANCE = 0,
                                   TBRACCD_TRAN_NUMBER_PAID = NULL,
                                   TBRACCD_DOCUMENT_NUMBER = 'CAMPQT',
                                   TBRACCD_ACTIVITY_DATE  = SYSDATE
                               WHERE TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM
                               AND TBRACCD_TRAN_NUMBER = PARCIALIDADES.TBRACCD_TRAN_NUMBER;
                      EXCEPTION
                      WHEN OTHERS THEN
                      VL_ERROR :=' Errror al actualizar saldo Saldo de la COL ANTERIOR >>  ' || SQLERRM ;
                      END;
                      
                      BEGIN
                               UPDATE TBRACCD
                               SET TBRACCD_TRAN_NUMBER_PAID = NULL,
                                   TBRACCD_ACTIVITY_DATE  = SYSDATE
                               WHERE TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM
                               AND TBRACCD_TRAN_NUMBER_PAID = PARCIALIDADES.TBRACCD_TRAN_NUMBER;
                      EXCEPTION
                      WHEN OTHERS THEN
                      VL_ERROR :=' Errror al actualizar saldo Saldo de la COL ANTERIOR >>  ' || SQLERRM ;
                      END;
                  
                  ELSIF PARCIALIDADES.TBBDETC_TYPE_IND = 'P' THEN
                    
                     BEGIN
                        UPDATE TBRACCD
                           SET TBRACCD_TRAN_NUMBER_PAID = NULL
                         WHERE     TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM
                               AND TBRACCD_TRAN_NUMBER_PAID = PARCIALIDADES.TBRACCD_TRAN_NUMBER;
                     END;
                                        
                     BEGIN               
                       SELECT MAX(TBRACCD_TRAN_NUMBER)+1 
                         INTO  VTRAN_MAX
                         FROM TBRACCD WHERE TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM ;
                     END;
                     
                     PKG_FINANZAS.P_DESAPLICA_PAGOS (PARCIALIDADES.TBRACCD_PIDM, PARCIALIDADES.TBRACCD_TRAN_NUMBER);
                                     
                      BEGIN            

                            INSERT 
                            INTO TBRACCD 
                                 (TBRACCD_PIDM, 
                                  TBRACCD_TRAN_NUMBER,
                                  TBRACCD_TERM_CODE,
                                  TBRACCD_DETAIL_CODE,
                                  TBRACCD_AMOUNT,
                                  TBRACCD_BALANCE,
                                  TBRACCD_DESC,
                                  TBRACCD_USER,
                                  TBRACCD_ENTRY_DATE,
                                  TBRACCD_EFFECTIVE_DATE,
                                  TBRACCD_TRANS_DATE,
                                  TBRACCD_SRCE_CODE,
                                  TBRACCD_ACCT_FEED_IND,
                                  TBRACCD_ACTIVITY_DATE,
                                  TBRACCD_SESSION_NUMBER,
                                  TBRACCD_SURROGATE_ID,
                                  TBRACCD_VERSION,
                                  TBRACCD_TRAN_NUMBER_PAID,
                                  TBRACCD_FEED_DATE,
                                  TBRACCD_STSP_KEY_SEQUENCE,
                                  TBRACCD_DATA_ORIGIN, 
                                  TBRACCD_PERIOD,
                                  TBRACCD_RECEIPT_NUMBER  )
                             VALUES(PARCIALIDADES.TBRACCD_PIDM, 
                                    VTRAN_MAX,
                                    PARCIALIDADES.TBRACCD_TERM_CODE ,
                                    VL_CODIGO, 
                                    PARCIALIDADES.TBRACCD_AMOUNT, 
                                    PARCIALIDADES.TBRACCD_AMOUNT, 
                                    VL_DESCR, 
                                    USER,
                                    SYSDATE,
                                    SYSDATE,
                                    SYSDATE,
                                    PARCIALIDADES.TBRACCD_SRCE_CODE,
                                    PARCIALIDADES.TBRACCD_ACCT_FEED_IND,
                                    PARCIALIDADES.TBRACCD_ACTIVITY_DATE,
                                    0,
                                    NULL,
                                    NULL,
                                    PARCIALIDADES.TBRACCD_TRAN_NUMBER,
                                    PARCIALIDADES.TBRACCD_FEED_DATE, 
                                    PARCIALIDADES.TBRACCD_STSP_KEY_SEQUENCE, 
                                    'CAMPQT',
                                    PARCIALIDADES.TBRACCD_PERIOD,
                                    PARCIALIDADES.TBRACCD_RECEIPT_NUMBER  );
                                    
                                    DBMS_OUTPUT.PUT_LINE('3');

                      END;
                                
                      BEGIN
                                  
                             UPDATE TBRACCD
                             SET TBRACCD_DOCUMENT_NUMBER = 'CAMPQT',
                                 TBRACCD_ACTIVITY_DATE = SYSDATE
                             WHERE TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM
                             AND TBRACCD_TRAN_NUMBER = VTRAN_MAX;
                                         
                      EXCEPTION
                      WHEN OTHERS THEN
                      VL_ERROR :=' Errror al actualizar saldo Pago>>  ' || SQLERRM ;
                      END;
                                     
                      BEGIN
                               UPDATE TBRACCD
                               SET TBRACCD_TRAN_NUMBER_PAID = VTRAN_MAX,
                                   TBRACCD_DOCUMENT_NUMBER = 'CAMPQT',
                                   TBRACCD_ACTIVITY_DATE  = SYSDATE
                               WHERE TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM
                               AND TBRACCD_TRAN_NUMBER = PARCIALIDADES.TBRACCD_TRAN_NUMBER;
                      EXCEPTION
                      WHEN OTHERS THEN
                      VL_ERROR :=' Errror al actualizar saldo Saldo de la COL ANTERIOR >>  ' || SQLERRM ;
                      END;
                      
                      BEGIN
                               UPDATE TBRACCD
                               SET TBRACCD_TRAN_NUMBER_PAID = NULL,
                                   TBRACCD_ACTIVITY_DATE  = SYSDATE
                               WHERE TBRACCD_PIDM = PARCIALIDADES.TBRACCD_PIDM
                               AND TBRACCD_TRAN_NUMBER_PAID = PARCIALIDADES.TBRACCD_TRAN_NUMBER;
                      EXCEPTION
                      WHEN OTHERS THEN
                      VL_ERROR :=' Errror al actualizar saldo Saldo de la COL ANTERIOR >>  ' || SQLERRM ;
                      END;
                           
                  END IF;
                            
                END LOOP;
                 
             END;
       
            
            
         END IF;
       
       ELSE
       
       VL_ERROR:= 'No se aplican ajustes, fecha milite para cambios = ';
       
       END IF;
   

   
   ELSE
   
   VL_ERROR:= 'NO EXISTEN TRANSACCIONES A CANCELAR';
   
   END IF;
   
   DBMS_OUTPUT.PUT_LINE('validacion final reprocesa cartera '||P_FECHA||' = '||VL_MATRICULA||' === '||VL_ERROR);
   
   
   IF (VL_ERROR IS NULL OR VL_ERROR = 'NO EXISTEN TRANSACCIONES A CANCELAR') THEN 
    VL_ERROR:= 'EXITO';     
   END IF;
   
   COMMIT;
   
   DBMS_OUTPUT.PUT_LINE(VL_ERROR);  
   
   RETURN VL_ERROR;
   
 END F_CARTERA_C_PQT;

--
--
FUNCTION F_PERIODO_FECHA_INI (P_PIDM NUMBER)RETURN VARCHAR2 IS

VL_RESULTADO        VARCHAR2(500);

 BEGIN

     BEGIN
       SELECT SORLCUR_TERM_CODE||','||TO_CHAR(SORLCUR_START_DATE,'DD/MM/YYYY')RETURNS
         INTO VL_RESULTADO
         FROM SORLCUR A
        WHERE     A.SORLCUR_PIDM = P_PIDM
              AND A.SORLCUR_LMOD_CODE = 'LEARNER'
              AND A.SORLCUR_ROLL_IND  = 'Y'
              AND A.SORLCUR_CACT_CODE = 'ACTIVE'
              AND A.SORLCUR_SEQNO IN (SELECT MAX (A1.SORLCUR_SEQNO)
                                     FROM SORLCUR A1
                                     WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                     AND A1.SORLCUR_ROLL_IND  = A.SORLCUR_ROLL_IND
                                     AND A1.SORLCUR_CACT_CODE = A.SORLCUR_CACT_CODE
                                     AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE);
     EXCEPTION
     WHEN OTHERS THEN
     VL_RESULTADO:='ERROR ';                                 
     END;
   RETURN(VL_RESULTADO);  
 END F_PERIODO_FECHA_INI;

    FUNCTION f_elimina_etiqueta (p_pidm IN NUMBER, p_atributo IN VARCHAR2, p_operador varchar2) RETURN VARCHAR2 -- Fer V1.03/06/2020

      IS 

      l_error VARCHAR2 (2500) := 'EXITO';
      l_max_periodo VARCHAR2 (2500); --p_periodo
      l_seq_sgrscmt NUMBER;
      l_operador VARCHAR2 (2500);
        
BEGIN

    BEGIN
        DELETE goradid 
        WHERE 1=1
        AND goradid_pidm = p_pidm
        AND goradid_adid_code = p_atributo; 
          
                          
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR AL ELIMINAR CÓDIGO EN GORADID '||SQLERRM);  
            l_error:= ('ERROR AL ELIMINAR CÓDIGO EN GORADID '||sqlerrm);
    END;

COMMIT;

RETURN(l_error);

END;

FUNCTION f_correo_existente(p_correo in varchar2) return varchar2
    IS
    l_correo  varchar(100);
    l_contar_co number;
    l_retorna_co varchar2(200):='Exito';
    
    Begin
    
    if p_correo is not null then       
 
       l_contar_co:=0;               
        BEGIN    
             SELECT COUNT(1)  INTO l_contar_co
             FROM  GOREMAL
             WHERE GOREMAL_EMAIL_ADDRESS = p_correo
             ;
             EXCEPTION
             WHEN OTHERS THEN
             l_retorna_co:=0;
        END;                
                   DBMS_OUTPUT.PUT_LINE('Contar '||l_contar_co);
            
        If l_contar_co > 0 THEN
          l_retorna_co :='Correo existente';
         End If;
         
   End If;
          
         return (l_retorna_co);
     
End;

FUNCTION F_INFO_DOCENTES (p_matricula in varchar2) RETURN PKG_ACTUALIZA_DATOS.cursor_out_info_docentes
           AS
                c_out_info_docentes PKG_ACTUALIZA_DATOS.cursor_out_info_docentes;

  BEGIN 
       open c_out_info_docentes
         FOR
                select distinct
                    SPRIDEN_PIDM PIDM,
                    SPRIDEN_ID MATRICULA,
                    regexp_substr(SPRIDEN_LAST_NAME, '[^/]*')||' '||NVL(substr(regexp_substr(SPRIDEN_LAST_NAME, '/[^/]*'),2), 0)||' '||SPRIDEN_FIRST_NAME NOMBRE,
                    GOREMAL_EMAIL_ADDRESS EMAIL,
                    STVFCST_DESC ESTATUS,
                    STVFCTG_DESC TIPO_DOCENTE
                from SPRIDEN, SIBINST, GOREMAL, STVFCST, STVFCTG
                where 1 = 1
                    and SPRIDEN_PIDM  = SIBINST_PIDM
                    and SIBINST_FCTG_CODE like 'D%'
                    and SPRIDEN_PIDM  = GOREMAL_PIDM
                    and GOREMAL_EMAL_CODE = 'PRIN'
                    and GOREMAL_STATUS_IND = 'A'
                    and SIBINST_FCST_CODE = STVFCST_CODE
                    and SIBINST_FCTG_CODE = STVFCTG_CODE
                    and SPRIDEN_ID like '0198%'
                    and SPRIDEN_CHANGE_IND is null
                    and SPRIDEN_ID = p_matricula
                    ;
                    
       RETURN (c_out_info_docentes);
       
       
  END;
  
FUNCTION f_actualiza_correo_docente(p_email in varchar2, 
                                                                p_pidm in number
                                                                ) return varchar2

IS                                                        
     l_retorna      varchar2(200):='Exito';
     l_spriden_id varchar2(100);
     

 begin
    
    if p_email is not null then
        
                Begin
                update GOREMAL
                set GOREMAL_EMAIL_ADDRESS = p_email,
                GOREMAL_ACTIVITY_DATE = SYSDATE
                where GOREMAL_PIDM = p_pidm
                    and GOREMAL_EMAL_CODE = 'PRIN';
                 COMMIT;                                                                           
                EXCEPTION
                WHEN OTHERS THEN
                l_retorna :=' Error al actualizar correo' || SQLERRM ;
                End;
     
    
                                l_spriden_id:= null;

                        begin
                            select spriden_id
                            into l_spriden_id
                            from spriden
                            where 1 = 1
                            and spriden_change_ind is null
                            and spriden_pidm = p_pidm;
                        
                        exception when others then
                            l_spriden_id:= null;
                        end;
               
        
                BEGIN
                    
                    INSERT INTO SZTBIMA(                                               
                                         sztbima_first_name,
                                         sztbima_last_name,
                                         sztbima_proceso,  
                                         sztbima_estatus,  
                                         sztbima_observaciones, 
                                         sztbima_pidm,
                                         sztbima_id,
                                         sztbima_email_address,
                                         sztbima_birth_date,
                                         sztbima_sex,
                                         sztbima_status_ind,
                                         sztbima_usuario_actualiza, 
                                         sztbima_fecha_actualiza
                                     )
                                     VALUES
                                     (
                                        null,
                                        null,
                                        'GOREMAL', 
                                        null,
                                        null, 
                                        p_pidm , 
                                        l_spriden_id,
                                        p_email,
                                        null,
                                        null,
                                        '1',
                                        USER,
                                        SYSDATE
                                );
                        EXCEPTION
                            WHEN OTHERS THEN        
                                 l_retorna:=('Error al actualizar correo docente en bitacora'||sqlerrm);
                        END;
                        
    End if;
    
        If l_retorna = 'Exito' then
         commit;
    else Rollback;
    End if;
    
    return (l_retorna);
                
 End;
 
   FUNCTION f_indiciplina(p_pidm in number) RETURN PKG_ACTUALIZA_DATOS.cursor_out_indi 
           AS
                c_out_indi PKG_ACTUALIZA_DATOS.cursor_out_indi;

--se garega un cambio a la funcion para que aun que no exista en tztprog mande la información de spriden
--   modifica glovicx 16/07021-----
  BEGIN 
       open c_out_indi         
         FOR SELECT DISTINCT
                b.spriden_pidm PIDM,
                b.spriden_id MATRICULA,
                b.spriden_first_name||' '||replace(b.spriden_last_name,'/',' ') NOMBRE_ALUMNO,
                g.goremal_email_address CORREO,
                t.ESTATUS Estatus,
                t.ESTATUS_D Descripcion_Estatus,
                t.PROGRAMA Programa,
                 upper( (select distinct SZTDTEC_PROGRAMA_COMP
                    from sztdtec
                    where 1 = 1
                    and SZTDTEC_PROGRAM = PROGRAMA
                    and rownum = 1))  descripcion_programa
                FROM spriden B,goremal g,tztprog t
                WHERE 1=1
                AND b.spriden_pidm = g.goremal_pidm
                AND b.spriden_pidm = t.PIDM(+)
                AND b.spriden_change_ind IS NULL
                AND ( g.goremal_emal_code ='PRIN'
                        or g.goremal_emal_code is null ) 
                AND b.spriden_pidm  = p_pidm;
       RETURN (c_out_indi);
       
  END;
  

--
--  

FUNCTION f_datos_grales(p_matricula in varchar2) RETURN PKG_ACTUALIZA_DATOS.cursor_out_dg
           AS
                c_out_dg PKG_ACTUALIZA_DATOS.cursor_out_dg;

  BEGIN 
       open c_out_dg         
         FOR 
         SELECT 
         B.SPRIDEN_ID MATRICULA,
         B.SPRIDEN_FIRST_NAME NOMBRE,
         REPLACE (B.SPRIDEN_LAST_NAME, '/', ' ')  APELLIDOS, 
--       SUBSTR (B.SPRIDEN_LAST_NAME, 1, INSTR (B.SPRIDEN_LAST_NAME, '/') - 1)
--          APELLIDO_PATERNO,
--       SUBSTR (B.SPRIDEN_LAST_NAME,
--               INSTR (B.SPRIDEN_LAST_NAME, '/') + 1,
--               150)
--          APELLIDO_MATERNO,
       C.GOREMAL_EMAIL_ADDRESS CORREO_PRINCIPAL,
       A.ESTATUS ESTATUS_CONE,
       D.ESTATUS_D ESTATUS_GENERAL
  FROM SZTCONE A,
       SPRIDEN B,
       GOREMAL C,
       TZTPROG D
 WHERE     A.PIDM = B.SPRIDEN_PIDM
       AND B.SPRIDEN_PIDM = C.GOREMAL_PIDM
       AND A.PIDM = D.PIDM
       AND B.SPRIDEN_ID = p_matricula
       AND B.SPRIDEN_CHANGE_IND IS NULL       
       AND C.GOREMAL_EMAL_CODE = 'PRIN'
       AND A.SECUENCIA = (SELECT MAX (E.SECUENCIA)
                            FROM SZTCONE E
                           WHERE A.PIDM = E.PIDM)
       AND C.GOREMAL_ACTIVITY_DATE =
              (SELECT MAX (F.GOREMAL_ACTIVITY_DATE)
                 FROM GOREMAL F
                WHERE     F.GOREMAL_PIDM = C.GOREMAL_PIDM
                      AND F.GOREMAL_EMAL_CODE = C.GOREMAL_EMAL_CODE)
       AND D.SP = (SELECT MAX (G.SP)
                     FROM TZTPROG G
                    WHERE G.PIDM = D.PIDM);
       RETURN (c_out_dg);
       
  END;
  

--
--  
FUNCTION f_ivr_siu(p_matricula in varchar2) RETURN SYS_REFCURSOR -- OMS 10/Junio/2025 PKG_ACTUALIZA_DATOS.cursor_out_is
           AS
                c_out_is SYS_REFCURSOR; -- OMS 10/Junio/2025 PKG_ACTUALIZA_DATOS.cursor_out_is;
                
 ln_tztprog NUMBER;
 Vm_Saldo   TBRACCD.tbraccd_amount%TYPE := 0;   -- Saldo al día
 
BEGIN

   -- Calculos del SALDO
   BEGIN
     SELECT SUM (tbraccd_balance) Saldo
       INTO Vm_Saldo
       FROM tbraccd a
      WHERE tbraccd_pidm = fget_pidm (p_matricula)
        AND NVL (tbraccd_amount,0) != 0
        AND TRUNC (tbraccd_effective_date) <= TRUNC (sysdate);
        
   EXCEPTION
      WHEN OTHERS THEN 
           Vm_Saldo := 0;
   END;

   SELECT COUNT (1)
     INTO ln_tztprog
     FROM tztprog
    WHERE pidm = fget_pidm (p_matricula);

   IF ln_tztprog > 0
   THEN
      OPEN c_out_is FOR
         SELECT B.SPRIDEN_FIRST_NAME NOMBRE,
                REPLACE (B.SPRIDEN_LAST_NAME, '/', ' ') APELLIDOS,
                C.GOREMAL_EMAIL_ADDRESS CORREO_PRINCIPAL,
                B.SPRIDEN_ID MATRICULA,
                A.GORADID_ADDITIONAL_ID REFERENCIA_PAGO,
                D.ESTATUS_D ESTATUS_GENERAL, Vm_Saldo Saldo
           FROM SPRIDEN B,
                GOREMAL C,
                TZTPROG D,
                GORADID A
          WHERE     B.SPRIDEN_PIDM = C.GOREMAL_PIDM
                AND D.PIDM = B.SPRIDEN_PIDM
                AND A.GORADID_PIDM = B.SPRIDEN_PIDM
                AND B.SPRIDEN_ID = p_matricula
                AND B.SPRIDEN_CHANGE_IND IS NULL
                AND C.GOREMAL_EMAL_CODE = 'PRIN'
                AND A.GORADID_ADID_CODE IN ('REFS', 'REFH')
                AND GOREMAL_STATUS_IND = 'A'
                AND C.GOREMAL_ACTIVITY_DATE =
                       (SELECT MAX (F.GOREMAL_ACTIVITY_DATE)
                          FROM GOREMAL F
                         WHERE     F.GOREMAL_PIDM = C.GOREMAL_PIDM
                               AND F.GOREMAL_EMAL_CODE = C.GOREMAL_EMAL_CODE)
                AND D.SP = (SELECT MAX (G.SP)
                              FROM TZTPROG G
                             WHERE G.PIDM = D.PIDM);

      RETURN (c_out_is);
   ELSE
      OPEN c_out_is FOR
         SELECT B.SPRIDEN_FIRST_NAME NOMBRE,
                REPLACE (B.SPRIDEN_LAST_NAME, '/', ' ') APELLIDOS,
                C.GOREMAL_EMAIL_ADDRESS CORREO_PRINCIPAL,
                B.SPRIDEN_ID MATRICULA,
                A.GORADID_ADDITIONAL_ID REFERENCIA_PAGO,
                D.ESTATUS_D ESTATUS_GENERAL, Vm_Saldo Saldo
           FROM SPRIDEN B,
                GOREMAL C,
                TZTPROG D,
                GORADID A
          WHERE     B.SPRIDEN_PIDM = C.GOREMAL_PIDM
                AND B.SPRIDEN_PIDM = D.PIDM(+)
                AND A.GORADID_PIDM = B.SPRIDEN_PIDM
                AND B.SPRIDEN_ID = p_matricula
                AND B.SPRIDEN_CHANGE_IND IS NULL
                AND C.GOREMAL_EMAL_CODE = 'PRIN'
                AND A.GORADID_ADID_CODE IN ('REFS', 'REFH')
                AND GOREMAL_STATUS_IND = 'A'
                AND C.GOREMAL_ACTIVITY_DATE =
                       (SELECT MAX (F.GOREMAL_ACTIVITY_DATE)
                          FROM GOREMAL F
                         WHERE     F.GOREMAL_PIDM = C.GOREMAL_PIDM
                               AND F.GOREMAL_EMAL_CODE = C.GOREMAL_EMAL_CODE);

      RETURN (c_out_is);
   END IF;
END;

  
FUNCTION f_cfecha_BLEN (p_pidm in number) RETURN PKG_ACTUALIZA_DATOS.cursor_out_cfecha_BLEN  -- FER v1 27/05/2024
           AS
                c_out_cfecha_BLEN PKG_ACTUALIZA_DATOS.cursor_out_cfecha_BLEN;

  BEGIN 
       open c_out_cfecha_BLEN         
         FOR 
            SELECT  
            c.SPRIDEN_ID MATRICULA, 
            upper ((c.spriden_first_name||' '||replace(c.spriden_last_name,'/',' '))) NOMBRE_ALUMNO, 
            d.ESTATUS_D ESTATUS_ALUMNO,
            d.NOMBRE PLAN_ESTUDIO,
            upper ((SELECT e.goremal_email_address FROM goremal E WHERE 1=1 AND e.goremal_pidm = a.SVRSVPR_PIDM AND e.goremal_emal_code = 'PRIN' AND e.GOREMAL_PREFERRED_IND = 'Y')) CORREO,
            b.SVRSVAD_PROTOCOL_SEQ_NO NO_SOLICITUD
            , (SELECT b1.SVRSVAD_ADDL_DATA_DESC  FROM SVRSVAD b1 WHERE 1=1 AND b1.SVRSVAD_PROTOCOL_SEQ_NO = a.SVRSVPR_PROTOCOL_SEQ_NO AND b1.SVRSVAD_ADDL_DATA_SEQ = 7) FECHA_INIC
            , upper ((SELECT b1.SVRSVAD_ADDL_DATA_CDE  FROM SVRSVAD b1 WHERE 1=1 AND b1.SVRSVAD_PROTOCOL_SEQ_NO = a.SVRSVPR_PROTOCOL_SEQ_NO AND b1.SVRSVAD_ADDL_DATA_SEQ in (10, 6))) ETIQUETA
            , upper ((SELECT b1.SVRSVAD_ADDL_DATA_DESC  FROM SVRSVAD b1 WHERE 1=1 AND b1.SVRSVAD_PROTOCOL_SEQ_NO = a.SVRSVPR_PROTOCOL_SEQ_NO AND b1.SVRSVAD_ADDL_DATA_SEQ in (10, 6))) SESION
            FROM SVRSVPR a, SVRSVAD b, SPRIDEN c, TZTPROG D
            WHERE 1=1
            AND a.SVRSVPR_PIDM = c.spriden_pidm
            AND a.SVRSVPR_PIDM = D.PIDM 
            and c.spriden_pidm = D.PIDM
            AND c.spriden_change_ind is null
            AND a.SVRSVPR_PROTOCOL_SEQ_NO = b.SVRSVAD_PROTOCOL_SEQ_NO
            AND a.SVRSVPR_SRVC_CODE = 'BLEN'
            AND a.SVRSVPR_SRVS_CODE = 'CL'
            AND a.SVRSVPR_PIDM = P_PIDM
            -- and c.spriden_id = '010032784'
            AND b.SVRSVAD_ADDL_DATA_SEQ = 7
            AND d.SP = (SELECT MAX (d1.SP)
                               FROM TZTPROG d1
                               WHERE 1=1
                               AND d1.PIDM = d.PIDM)
                                       ;
                   
       RETURN (c_out_cfecha_BLEN);
       
  END;
  
--
--
FUNCTION   f_act_fecha_BLEN (p_new_fecha VARCHAR2, p_seqno NUMBER, p_user VARCHAR2) Return varchar2 -- V1 fer 27/05/2024

  IS
  
  vl_exito varchar2(500):= 'EXITO';
  
  BEGIN 

             
                BEGIN 
                    update SVRSVAD
                    set 
                    SVRSVAD_ADDL_DATA_DESC = p_new_fecha,
                    SVRSVAD_ACTIVITY_DATE = SYSDATE,
                    SVRSVAD_USER_ID = p_user, 
                    SVRSVAD_DATA_ORIGIN = 'CAMB_FECHA_SIU'
                    where 1=1
                    and SVRSVAD_PROTOCOL_SEQ_NO = p_seqno
                    and SVRSVAD_ADDL_DATA_SEQ = 7;

                EXCEPTION
                    WHEN OTHERS THEN
                     return ('fallo actualizar fecha de inicio');  
                END;
                
      COMMIT;

    RETURN ('EXITO');            
                
  END;  

--

--
--  
END PKG_ACTUALIZA_DATOS;
/

DROP PUBLIC SYNONYM PKG_ACTUALIZA_DATOS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ACTUALIZA_DATOS FOR BANINST1.PKG_ACTUALIZA_DATOS;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_ACTUALIZA_DATOS TO PUBLIC;
