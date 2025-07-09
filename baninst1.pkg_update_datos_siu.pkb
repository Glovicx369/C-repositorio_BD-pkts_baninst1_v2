DROP PACKAGE BODY BANINST1.PKG_UPDATE_DATOS_SIU;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_UPDATE_DATOS_SIU IS

/*
PAKETE PARA QUE LOS ALUMNOS Y LOS TUTORES PUEDAN HACER CAMBIOS A LA INFORMACIÓN DE LOS ALUMNOS
DESARROLLO GLOVICX 03/06/022

Datos personales
Nombre del alumno SPBPERS
Correo electrónico  GOREMAL
Fecha de nacimiento SPBPERS

Datos de Identidad
Estado Civil   SPBPERS
Género  SPBPERS
CURP GORADID (CURP)

Número Telefónico
Principal SPRTELE (RESI)
Celular SPRTELE (CELU)
Alterno SPRTELE (ALTE)

Dirección Residencia SPRADDR (RE)
última modify 21.02.2023 glovicx
*/
VSALIDA VARCHAR2(500):= 'EXITO';


FUNCTION F_UPD_PERSONALES (PPIDM IN NUMBER, PNOMBRE IN VARCHAR2, PPATERNO IN VARCHAR2,PMATERNO IN VARCHAR2, PMAIL IN VARCHAR2, PFECHA_NAC IN VARCHAR2 , PUSER VARCHAR2 ) RETURN VARCHAR2 IS


VnombreXX    varchar2(100);
vapellidos   varchar2(100);
vnombre      varchar2(100);

BEGIN
NULL;
/*
--Datos personales
--Nombre del alumno SPBPERS
--Correo electrónico  GOREMAL
--Fecha de nacimiento SPBPERS
Nombre o Nombre: SPRIDEN_FIRST_NAME
Apellido: SPRIDEN_LAST_NAME (Apellido paterno y materno y se debe de separar por una Diaguna ("/")).

*/
VSALIDA := 'EXITO';
--- esta belleza lo que hace es quitar acentos,espacios dobles o triple en blancoen medio de la cadena y quitar simbolos
-- caracteres especiales como *+´}{-.?= y deja todo en mayusculas,  lo diseño glovicx 29.06.022



  begin
        select TO_CHAR( REGEXP_REPLACE(
        UPPER(utl_raw.cast_to_varchar2(nlssort(regexp_replace(
        regexp_replace(PNOMBRE||' '||PPATERNO||' '||PMATERNO , '[(][A-Z]+[)]', ''), '[^a-zA-Z-0-9]', ' '), 'nls_sort=binary_ai')))
        , ' {2,}', ' ')
        )
        INTO VnombreXX
        FROM DUAL;
  exception when others then
          VnombreXX := 'NA';
  end;


  begin
        select TO_CHAR( REGEXP_REPLACE(
        UPPER(utl_raw.cast_to_varchar2(nlssort(regexp_replace(
        regexp_replace(PPATERNO||' '||PMATERNO , '[(][A-Z]+[)]', ''), '[^a-zA-Z-0-9]', ' '), 'nls_sort=binary_ai')))
        , ' {2,}', ' ')
        )
        INTO vapellidos
        FROM DUAL;
  exception when others then
          vapellidos := 'NA';
  end;


  begin
        select TO_CHAR( REGEXP_REPLACE(
        UPPER(utl_raw.cast_to_varchar2(nlssort(regexp_replace(
        regexp_replace(PNOMBRE , '[(][A-Z]+[)]', ''), '[^a-zA-Z-0-9]', ' '), 'nls_sort=binary_ai')))
        , ' {2,}', ' ')
        )
        INTO vnombre
        FROM DUAL;
  exception when others then
          vapellidos := 'NA';
  end;


      --dbms_output.put_line('salida ' || VnombreXX );



  BEGIN

    UPDATE SPBPERS P
         SET P.SPBPERS_BIRTH_DATE    = TO_date(PFECHA_NAC, 'DD/MM/YYYY'),
             P.SPBPERS_LEGAL_NAME    =VnombreXX,
             P.SPBPERS_USER_ID       = PUSER,
             P.SPBPERS_ACTIVITY_DATE = SYSDATE
        WHERE 1=1
           AND P.SPBPERS_PIDM = PPIDM;

  EXCEPTION WHEN OTHERS THEN
   VSALIDA := SQLERRM;

    dbms_output.put_line('salida funcion errorrr spbpers : '||   vsalida);

  END;

--dbms_output.put_line('salida funn  spbpers 1: '||   vsalida);

 IF PMAIL is null then
   null; -- no hace nada
  ELSE
   BEGIN
    UPDATE GOREMAL G
      SET G.GOREMAL_EMAIL_ADDRESS = PMAIL,
          G.GOREMAL_USER_ID       = PUSER,
          G.GOREMAL_ACTIVITY_DATE = SYSDATE
        WHERE 1=1
        AND G.GOREMAL_EMAL_CODE = 'PRIN'
        AND G.GOREMAL_PIDM   = PPIDM
        and G.GOREMAL_PREFERRED_IND = 'Y';


  EXCEPTION WHEN OTHERS THEN
   VSALIDA := SQLERRM;

   dbms_output.put_line('salida funcion errorrr goremail : '||   vsalida);

  END;
  end if;


--dbms_output.put_line('salida funn goremal 2: '||   vsalida||'-'||PNOMBRE||'-'||PPATERNO ||'-'||PMATERNO  );
--- AHORA SE HACE EL UPDATE EN SPRIDEN--
   BEGIN
      UPDATE SPRIDEN S
         SET S.SPRIDEN_FIRST_NAME = PNOMBRE,
             S.SPRIDEN_LAST_NAME  = PPATERNO||'/'||PMATERNO ,
             S.SPRIDEN_SEARCH_LAST_NAME   = vapellidos,
             S.SPRIDEN_SEARCH_FIRST_NAME  = vnombre,
             S.SPRIDEN_ACTIVITY_DATE = SYSDATE,
             S.SPRIDEN_USER_ID   = USER
       WHERE 1=1
         AND S.SPRIDEN_PIDM   = PPIDM
         AND S.SPRIDEN_CHANGE_IND IS NULL;

    EXCEPTION WHEN OTHERS THEN
   VSALIDA := SQLERRM;

   dbms_output.put_line('salida funcion errorrr SPRIDENT  : '||   vsalida);

  END;

--dbms_output.put_line('salida funn  spriden 3: '||   vsalida);


---se agrega una nuevo insert a petición de fernando 18/07/022

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
                                'REG_ACT',
                                PPIDM ,
                                F_GetSpridenID(PPIDM),
                                PMAIL,
                                null,
                                null,
                                '7',
                                USER,
                                SYSDATE
                        );
         EXCEPTION
                    WHEN OTHERS THEN
                         VSALIDA:=('Error al insertar correo en bitacora'||sqlerrm);
        END;

    -- dbms_output.put_line('alterminal proceso de insert en ztbima  : '||   vsalida);
COMMIT;

RETURN VSALIDA;

EXCEPTION WHEN OTHERS THEN
ROLLBACK;

   dbms_output.put_line('salida errorrr general  : '||   vsalida);
RETURN SQLERRM;



END F_UPD_PERSONALES;


FUNCTION F_UPD_IDENTIDAD (PPIDM IN NUMBER,PCIVIL VARCHAR2,PGENERO VARCHAR2, PCURP VARCHAR2, PUSER VARCHAR2) RETURN VARCHAR2 IS

--Datos de Identidad
--Estado Civil   SPBPERS
--Género  SPBPERS
--CURP GORADID (CURP)
BEGIN

VSALIDA := 'EXITO';

        BEGIN

       UPDATE SPBPERS P
         SET P.SPBPERS_SEX        = PGENERO,
             P.SPBPERS_MRTL_CODE  = PCIVIL,
             P.SPBPERS_USER_ID    = PUSER,
             P.SPBPERS_ACTIVITY_DATE = SYSDATE
        WHERE 1=1
        AND P.SPBPERS_PIDM = PPIDM;



      EXCEPTION WHEN OTHERS THEN
       VSALIDA := SQLERRM;

      END;

      IF PCURP IS NULL THEN
      NULL; --NO HACE NADA
      ELSE
      BEGIN
            UPDATE GORADID
               SET GORADID_ADDITIONAL_ID = PCURP,
                   GORADID_USER_ID       = PUSER,
                   GORADID_ACTIVITY_DATE = SYSDATE
                WHERE 1=1
                AND GORADID_ADID_CODE = 'CURP'
                AND GORADID_PIDM = PPIDM;


      EXCEPTION WHEN OTHERS THEN
       VSALIDA := SQLERRM;

      END;
      END IF;


IF VSALIDA = 'EXITO' THEN

COMMIT;
ELSE

ROLLBACK;

END IF;


   RETURN VSALIDA;


EXCEPTION WHEN OTHERS THEN
ROLLBACK;
RETURN SQLERRM;

END F_UPD_IDENTIDAD;

FUNCTION F_UPD_TELEFONOS (PPIDM IN NUMBER, PPHONE NUMBER, PAREA VARCHAR2, PEXT VARCHAR2,PCODE VARCHAR2,  PUSER VARCHAR2, PCODE_CTRY VARCHAR2 ) RETURN VARCHAR2 IS

--Número Telefónico
--Principal SPRTELE (RESI)
--Celular SPRTELE (CELU)
--Alterno SPRTELE (ALTE)

VVAL_TELF    VARCHAR2(1):= 'Y';
VMAX_TELF    NUMBER:= 0;

BEGIN
VSALIDA := 'EXITO';

-----primero validamos si existe el telefono y su tipo
    begin

            SELECT DISTINCT  'Y'
              INTO VVAL_TELF
            FROM SPRTELE
            WHERE 1=1
            AND SPRTELE_TELE_CODE = PCODE
            AND SPRTELE_PIDM = PPIDM;


     EXCEPTION WHEN OTHERS THEN
      -- VSALIDA := SQLERRM;
       VVAL_TELF := 'N';
      DBMS_OUTPUT.PUT_LINE('ERROR BUSCA TELEFONO:NUEVO  ' || VVAL_TELF );
     end;


   IF VVAL_TELF = 'Y'  THEN
      BEGIN

          UPDATE SPRTELE T
             SET  T.SPRTELE_PHONE_AREA  =  PCODE_CTRY,
                  T.SPRTELE_PHONE_NUMBER = PAREA||PPHONE ,
                  T.SPRTELE_PHONE_EXT    = PEXT,
                  T.SPRTELE_ACTIVITY_DATE = SYSDATE,
                  T.SPRTELE_USER_ID       = PUSER,
                  t.SPRTELE_CTRY_CODE_PHONE = PCODE_CTRY
            WHERE 1=1
                AND SPRTELE_TELE_CODE = PCODE
                AND SPRTELE_PIDM = PPIDM;


         EXCEPTION WHEN OTHERS THEN
       VSALIDA := SQLERRM;

      END;

   ELSE
      ----- BUSCAMOS EL MAX SEQNO
        BEGIN
             SELECT MAX(T.SPRTELE_SEQNO)+1
              INTO VMAX_TELF
            FROM SPRTELE T
            WHERE 1=1
            AND SPRTELE_PIDM = PPIDM;

       EXCEPTION WHEN OTHERS THEN
       --VSALIDA := SQLERRM;
        VMAX_TELF := 1;
      END;

      BEGIN--- SE HACE EL INSERT DEL REGISTRO
        INSERT INTO SPRTELE (
                    SPRTELE_PIDM,
                    SPRTELE_SEQNO,
                    SPRTELE_TELE_CODE,
                    SPRTELE_ACTIVITY_DATE,
                    SPRTELE_SURROGATE_ID,
                    SPRTELE_VERSION,
                    SPRTELE_PHONE_AREA,
                    SPRTELE_PHONE_NUMBER,
                    SPRTELE_PHONE_EXT,
                    SPRTELE_DATA_ORIGIN,
                    SPRTELE_USER_ID,
                    SPRTELE_CTRY_CODE_PHONE
                    )
            VALUES(PPIDM,VMAX_TELF,PCODE, SYSDATE, NULL, null,PCODE_CTRY,PAREA||PPHONE,PEXT,'INSR_SIU',PUSER,PCODE_CTRY );


       EXCEPTION WHEN OTHERS THEN
       VSALIDA := SQLERRM;
        DBMS_OUTPUT.PUT_LINE('ERROR EL INSERTAR NUEVO TELEFONO:  ' || VSALIDA );
      END;


   END IF;


IF VSALIDA = 'EXITO' THEN

COMMIT;
ELSE

ROLLBACK;

END IF;

RETURN VSALIDA;


EXCEPTION WHEN OTHERS THEN
ROLLBACK;
RETURN SQLERRM;

END F_UPD_TELEFONOS;

FUNCTION F_RESIDENCIA (PPIDM NUMBER,PCODE VARCHAR2,PSTREET1 VARCHAR2,PSTREET2 VARCHAR2,PSTREET3 VARCHAR2,PCITY VARCHAR2,PSTAT_CODE VARCHAR2,
                       PCP  VARCHAR2,PCNTY_CODE  VARCHAR2,NATN_CODE VARCHAR2,PUSER VARCHAR2   ) RETURN VARCHAR2 IS

--Dirección Residencia SPRADDR (RE)

vresi   varchar2(1):='N';
vseqno    number:= 0;


BEGIN
VSALIDA := 'EXITO';

---- primero se valida  si existe existe el codigo de residencia lo actualiza y si no lo inserta-- regla fer 08.02.2023
      begin

        select distinct  'Y'
           into vresi
            from  SPRADDR d
            WHERE 1=1
            AND D.SPRADDR_PIDM  = PPIDM
            AND D.SPRADDR_ATYP_CODE = PCODE
            and  d.SPRADDR_SEQNO = ( select max(d2.SPRADDR_SEQNO)  from SPRADDR d2
                                                        WHERE 1=1
                                                        AND D.SPRADDR_PIDM  = D2.SPRADDR_PIDM
                                                        AND D.SPRADDR_ATYP_CODE = D2.SPRADDR_ATYP_CODE )
            ;

      exception when others then
        vresi := 'N';
      end;


      begin

          select nvl(max(d2.SPRADDR_SEQNO),0)+1
                into vseqno
               from SPRADDR d2
                    WHERE 1=1
                    AND D2.SPRADDR_PIDM  = PPIDM
                    ;

      exception when others then
        vseqno := 1;

      end;


         --dbms_output.put_line('despues de validaxxx :: '||  vresi ||'-'|| vseqno );
   IF VRESI = 'N'  THEN

       BEGIN

          INSERT INTO SPRADDR (SPRADDR_PIDM, SPRADDR_ATYP_CODE,SPRADDR_SEQNO, SPRADDR_STREET_LINE1, SPRADDR_STREET_LINE2, SPRADDR_STREET_LINE3,SPRADDR_CITY ,
                                             SPRADDR_STAT_CODE , SPRADDR_ZIP ,SPRADDR_CNTY_CODE,SPRADDR_NATN_CODE,SPRADDR_USER,SPRADDR_ACTIVITY_DATE,SPRADDR_SURROGATE_ID)
                                 Values(PPIDM, pcode,vseqno, PSTREET1,PSTREET2,PSTREET3,PCITY,PSTAT_CODE, PCP,PCNTY_CODE, NATN_CODE, PUSER, sysdate,null );
          exception when others then
           VSALIDA := SQLERRM;

       END;

   -- dbms_output.put_line('despues de insert  :: '||  vresi  );
   ELSE
    BEGIN
          UPDATE SPRADDR D
            SET D.SPRADDR_STREET_LINE1  =PSTREET1||' , '||PSTREET2 ,
               -- D.SPRADDR_STREET_LINE2  =PSTREET2,
                D.SPRADDR_STREET_LINE3  =Pstreet3,
                D.SPRADDR_CITY        =PCITY,
                D.SPRADDR_STAT_CODE   =PSTAT_CODE,
                D.SPRADDR_ZIP         =PCP,
                D.SPRADDR_CNTY_CODE   =PCNTY_CODE,
                D.SPRADDR_NATN_CODE   =NATN_CODE,
                D.SPRADDR_USER        =PUSER,
                D.SPRADDR_ACTIVITY_DATE = SYSDATE
          WHERE 1=1
            AND D.SPRADDR_PIDM  = PPIDM
            AND D.SPRADDR_ATYP_CODE = PCODE;

     EXCEPTION WHEN OTHERS THEN
       VSALIDA := SQLERRM;

      END;
 END IF; ---IF RESI

IF VSALIDA = 'EXITO' THEN

COMMIT;
ELSE

ROLLBACK;

END IF;


RETURN VSALIDA;


EXCEPTION WHEN OTHERS THEN
ROLLBACK;
RETURN SQLERRM;

END F_RESIDENCIA;





FUNCTION f_alumnos_out (p_matricula in varchar2) RETURN PKG_UPDATE_DATOS_SIU.cur_alumno_type
 AS
 c_out PKG_UPDATE_DATOS_SIU.cur_alumno_type;

VCIVIL      VARCHAR2(20);
varea_cel   VARCHAR2(20);
vnumcel     VARCHAR2(20);
varea_ho   VARCHAR2(20);
vnumhome     VARCHAR2(20);
varea_ofi   VARCHAR2(20);
vnumofi     VARCHAR2(20);
VFECHA_NAC   VARCHAR2(20);
VSEXO        VARCHAR2(2);

VSTREET33  varchar2(15);
VSTREET3   varchar2(150);
VNATN_CODE  varchar2(15);
VSTAT_CODE  varchar2(15);
VCNTY_CODE  varchar2(15);
VCP         varchar2(15);
VCITY       VARCHAR2(50);
VLINE1      VARCHAR2(150);
-------nueva direccion
VSTREET32   varchar2(150);
VNATN_CODE2  varchar2(15);
VSTAT_CODE2  varchar2(15);
VCNTY_CODE2  varchar2(15);
VCP2         varchar2(15);
VCITY2       VARCHAR2(50);
VLINE12      VARCHAR2(150);
VCTRY_CEL      VARCHAR2(5);
VCTRY_HO      VARCHAR2(5);
VCTRY_OFI      VARCHAR2(5);
vssn              varchar2(20);

 BEGIN

    BEGIN

        SELECT STVMRTL_CODE CIVIL
        INTO VCIVIL
        FROM STVMRTL T, SPBPERS S
        WHERE 1=1
        AND S.SPBPERS_MRTL_CODE = T.STVMRTL_CODE
        AND S.SPBPERS_PIDM  = FGET_PIDM(p_matricula);

    EXCEPTION WHEN OTHERS THEN
    VCIVIL := 'N/A';
     DBMS_OUTPUT.PUT_LINE('errror  civil:  '|| VCIVIL  );
    END;

 --DBMS_OUTPUT.PUT_LINE('al finalizar civil:  '|| VCIVIL  );



    Begin
       Select sprtele_phone_area, sprtele_phone_number,TELE.SPRTELE_CTRY_CODE_PHONE
         Into varea_cel, vnumcel,VCTRY_CEL
         from sprtele tele
         Where  tele.sprtele_pidm = FGET_PIDM(p_matricula)
         and tele.sprtele_tele_code = 'CELU'
        -- and sprtele_primary_ind = 'Y'
         and tele.sprtele_surrogate_id = (select max (tele1.sprtele_surrogate_id)
                                                                  from sprtele tele1
                                                                  where tele.sprtele_pidm = tele1.sprtele_pidm
                                                                  and  tele.sprtele_tele_code =  tele1.sprtele_tele_code);
    Exception
        When Others then
            varea_cel := null;
             vnumcel  := null;
       DBMS_OUTPUT.PUT_LINE('errror  celular: ' ||varea_cel||'-'|| vnumcel || sqlerrm  );
    End;

     Begin
       Select sprtele_phone_area, sprtele_phone_number,SPRTELE_CTRY_CODE_PHONE
         Into varea_ho, vnumhome,VCTRY_HO
         from sprtele tele
         Where  tele.sprtele_pidm = FGET_PIDM(p_matricula)
         and tele.sprtele_tele_code = 'RESI'
        -- and sprtele_primary_ind = 'Y'
         and tele.sprtele_surrogate_id = (select max (tele1.sprtele_surrogate_id)
                                                                  from sprtele tele1
                                                                  where tele.sprtele_pidm = tele1.sprtele_pidm
                                                                  and  tele.sprtele_tele_code =  tele1.sprtele_tele_code);
    Exception
        When Others then
            varea_ho := null;
             vnumhome  := null;
        DBMS_OUTPUT.PUT_LINE('errror  home:  '|| sqlerrm  );
    End;

     Begin
       Select sprtele_phone_area, sprtele_phone_number,SPRTELE_CTRY_CODE_PHONE
         Into varea_OFI, vnumofi,VCTRY_OFI
         from sprtele tele
         Where  tele.sprtele_pidm = FGET_PIDM(p_matricula)
         and tele.sprtele_tele_code = 'OFIC'
        -- and sprtele_primary_ind = 'Y'
         and tele.sprtele_surrogate_id = (select max (tele1.sprtele_surrogate_id)
                                                                  from sprtele tele1
                                                                  where tele.sprtele_pidm = tele1.sprtele_pidm
                                                                  and  tele.sprtele_tele_code =  tele1.sprtele_tele_code);
    Exception
        When Others then
            varea_ofi := null;
             vnumofi  := null;
         DBMS_OUTPUT.PUT_LINE('errror  ofi:  '|| sqlerrm  );
    End;


                Begin

                select distinct to_char( SPBPERS_BIRTH_DATE, 'DD/MM/YYYY'),SPBPERS_SEX
                    Into VFECHA_NAC, VSEXO
                from SPBPERS
                where 1 = 1
                    and SPBPERS_PIDM = FGET_PIDM(p_matricula);

                Exception
                    When Others then
                        VFECHA_NAC := null;
                        VSEXO      := NULL;
                End;


 ----deacuerdo a las nuevas reglas de Fernando 10.08.022 se va buscar el codig oen una tanla nueva
-- ese código es el que se va a poner en la tabla de  SPRADDR en el campo SPRADDR_STREET_LINE3

     begin

            select     D.SPRADDR_NATN_CODE,
                       D.SPRADDR_STAT_CODE,
                       D.SPRADDR_CNTY_CODE,
                       D.SPRADDR_ZIP,
                       D.SPRADDR_STREET_LINE3,
                       d.SPRADDR_CITY,
                       D.SPRADDR_STREET_LINE1
             INTO  VNATN_CODE, VSTAT_CODE, VCNTY_CODE,VCP, VSTREET3, VCITY, VLINE1
            from SPRADDR d
            WHERE 1=1
            AND D.SPRADDR_PIDM  = FGET_PIDM(p_matricula)
            AND D.SPRADDR_ATYP_CODE = 'RE';


     EXCEPTION WHEN OTHERS THEN
       VSALIDA := SQLERRM;

      END;

         begin

            select  D.SPRADDR_NATN_CODE,
                       D.SPRADDR_STAT_CODE,
                       D.SPRADDR_CNTY_CODE,
                       D.SPRADDR_ZIP,
                       D.SPRADDR_STREET_LINE3,
                       d.SPRADDR_CITY,
                       D.SPRADDR_STREET_LINE1
             INTO  VNATN_CODE2, VSTAT_CODE2, VCNTY_CODE2,VCP2, VSTREET32, VCITY2, VLINE12
            from SPRADDR d
            WHERE 1=1
            AND D.SPRADDR_PIDM  = FGET_PIDM(p_matricula)
            AND D.SPRADDR_ATYP_CODE = 'CO';


     EXCEPTION WHEN OTHERS THEN
       VSALIDA := SQLERRM;

      END;


/*
    begin


        select  xx.GTVZIPC_CODE||'-'||xx.numero
                 INTO vstreet33
        from (
                    select  GTVZIPC_CODE, GTVZIPC_CITY, rownum numero
                        from Gtvzipc g
                        where 1=1
                         and GTVZIPC_NATN_CODE = VNATN_CODE
                                        and GTVZIPC_STAT_CODE = VSTAT_CODE
                                        and GTVZIPC_CNTY_CODE = VCNTY_CODE
                                        and GTVZIPC_CODE      = VCP
                        order by GTVZIPC_CITY
                        ) xx
            where 1=1
            and xx.GTVZIPC_CITY  like('%'||VSTREET3||'%');


     EXCEPTION WHEN OTHERS THEN
       VSALIDA := SQLERRM;

      END;
 */

   BEGIN

            select DISTINCT decode(SPBPERS_SSN, null,'NA') SSN
            into vssn
            from SPBPERS
            where 1=1
            and SPBPERS_PIDM  = FGET_PIDM(p_matricula);

   END;


 --dbms_output.put_line('Salida code  '|| vstreet33 ||'-'|| VNATN_CODE||'-'||VSTAT_CODE ||'-'||VCNTY_CODE||'-'||VCP||'-'|| VSTREET3||'-'|| VLINE1);

 --dbms_output.put_line('Salida direcion nueva '|| vstreet32 ||'-'|| VNATN_CODE2||'-'||VSTAT_CODE2 ||'-'||VCNTY_CODE2||'-'||VCP2||'-'|| VSTREET32||'-'|| VLINE12);

 open c_out
 FOR  select substr (b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME,'/')-1) paterno,
         substr (b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME,'/')+1,150) materno ,
         B.SPRIDEN_FIRST_NAME Nombre,
         pkg_utilerias.f_correo(a.pidm, 'PRIN') Correo,
         trim(pkg_utilerias.f_etiqueta(a.pidm, 'CURP')) Curp,
         VFECHA_NAC,
         varea_cel, vnumcel,VCTRY_CEL,
          varea_ho, vnumhome,VCTRY_HO,
          varea_OFI, vnumofi,VCTRY_OFI,
         --pkg_utilerias.f_genero(a.pidm) Genero,
           VSEXO,
           VCIVIL,
           VLINE1, --D.SPRADDR_STREET_LINE1,
           VSTREET3, --D.SPRADDR_STREET_LINE3,
           VCITY, --D.SPRADDR_CITY,
           VSTAT_CODE, -- D.SPRADDR_STAT_CODE,
           VCP, --D.SPRADDR_ZIP,
           VCNTY_CODE,--VCNTY_CODE, --D.SPRADDR_CNTY_CODE,
           VNATN_CODE --D.SPRADDR_NATN_CODE
         , VLINE12  ---nueva direccion
         , VSTREET32
          , VCITY2
          , VSTAT_CODE2
          , VCP2
          , VCNTY_CODE2
          , VNATN_CODE2
          ,vssn
        from tztprog_all a
             join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
           --  left outer JOIN SPRADDR D ON  D.SPRADDR_PIDM = a.pidm  AND   D.SPRADDR_PIDM = B.SPRIDEN_PIDM
                 where 1= 1
                     And a.estatus not in ('CV')
                     And a.sp = (select max (a1.sp)
                                 from tztprog_all a1
                                 Where a.pidm = a1.pidm
                                 And a.PROGRAMA = a1.PROGRAMA)
                     And a.matricula = p_matricula;


RETURN c_out;

exception when others then

DBMS_OUTPUT.PUT_LINE('errror  civil:  '|| sqlerrm  );

end f_alumnos_out;


FUNCTION f_phone_out (p_matricula in varchar2) RETURN PKG_UPDATE_DATOS_SIU.cur_phone_type
 AS
 phone_out PKG_UPDATE_DATOS_SIU.cur_phone_type;

begin

 open phone_out
     FOR   Select  '('||SPRTELE_PHONE_AREA||')' area, sprtele_phone_number numero, SPRTELE_TELE_CODE tipo
                  from sprtele tele
                     Where  tele.sprtele_pidm = FGET_PIDM(p_matricula)
                     and tele.sprtele_tele_code != 'XX'
                  --   and sprtele_primary_ind = 'Y'
                     and tele.SPRTELE_SEQNO = (select max (tele1.SPRTELE_SEQNO)
                                                                              from sprtele tele1
                                                                              where tele.sprtele_pidm = tele1.sprtele_pidm
                                                                              and  tele.sprtele_tele_code =  tele1.sprtele_tele_code);


RETURN phone_out;

exception when others then

DBMS_OUTPUT.PUT_LINE('errror  de telefono cursorl:  '|| sqlerrm  );
end f_phone_out;


FUNCTION F_IDID  ( PPIDM NUMBER, PIDID VARCHAR2, PCAMPUS VARCHAR2, PUSER VARCHAR2   ) RETURN VARCHAR IS
--ESTA FUNCION SIRVE para actulizar los SNN o idid de la expansión LATAM, ya que muchas veces tiene más caracteres de los
--  que soporta la tabla. GLOVICX 02.05.2023
VVALIDA VARCHAR2(1):='N';
VSALIDA  VARCHAR2(500):= 'EXITO' ;

BEGIN
---  HAY QUE VALIDAR EL CAMPUS NO APLICA PARA UTL REGLA BETZY
IF PCAMPUS IN ('UTS','UTL')  THEN
NULL;
-- NO HACE NADA

ELSE
dbms_output.put_line('inicio    '|| PCAMPUS  );
-- VALIDA SI EXISTE EN SPBPERS-- TODA LA EXPANSIÓN
          BEGIN
             SELECT DECODE(S.SPBPERS_SSN,'','Y', 'Y')   SNN
               INTO VVALIDA
             FROM SPBPERS S
               WHERE 1=1
                 AND S.SPBPERS_PIDM = PPIDM ;

          EXCEPTION WHEN OTHERS THEN
            VVALIDA := 'N';
         END;

  dbms_output.put_line('inicio spbpers   '|| VVALIDA  );


       IF VVALIDA = 'Y'  THEN
            -- VAMOS A ACTUALIZAR--
            BEGIN
                     UPDATE SPBPERS S
                      SET S.SPBPERS_SSN = SUBSTR(PIDID,1,15),
                            S.SPBPERS_ACTIVITY_DATE = SYSDATE,
                            S.SPBPERS_USER_ID  = PUSER
                   WHERE 1=1
                     AND S.SPBPERS_PIDM = PPIDM;

              EXCEPTION WHEN OTHERS THEN
                VSALIDA := SQLERRM;
              END;

               dbms_output.put_line('UPDATE  spbpers   '|| VVALIDA  );
        ELSE

          NULL;
          VSALIDA := 'N';
         -- VALIDAR SI FALTA UNA REGLA
       END IF;



       IF VSALIDA = 'EXITO'  THEN
           VVALIDA := NULL; -- SETEAMO LA VARIABLE PARA SU REUSO


                    --- VALIDAMOS GORADID---
                           BEGIN
                               SELECT 'Y'
                               INTO VVALIDA
                                 FROM  GORADID
                                      WHERE 1=1
                                                 AND GORADID_PIDM  = PPIDM
                                                 AND GORADID_ADID_CODE  = 'IDID';


                           EXCEPTION WHEN OTHERS THEN
                             VVALIDA := 'N';
                           END;


            IF VVALIDA = 'Y'  THEN
                 -- ACTUALIZAMOS GORADID---
                  dbms_output.put_line('update goradid   '|| VVALIDA  );

                      BEGIN
                        UPDATE GORADID G
                           SET G.GORADID_ADDITIONAL_ID = PIDID,
                                   G.GORADID_ACTIVITY_DATE = SYSDATE,
                                   G.GORADID_USER_ID           =PUSER
                           WHERE 1=1
                             AND GORADID_PIDM  = PPIDM
                             AND GORADID_ADID_CODE  = 'IDID';

                         EXCEPTION WHEN OTHERS THEN
                        VSALIDA := SQLERRM;
                      END;

               ELSE
                 dbms_output.put_line('insert-- goradid   '|| VVALIDA  );
               ----- REGLA SI NO SE ACTUALIZA SE INSERTA
                   BEGIN
                    INSERT INTO GORADID(GORADID_PIDM,
                                        GORADID_ADDITIONAL_ID,
                                        GORADID_ADID_CODE,
                                        GORADID_USER_ID,
                                        GORADID_ACTIVITY_DATE,
                                        GORADID_DATA_ORIGIN,
                                        GORADID_SURROGATE_ID,
                                        GORADID_VERSION)
                    VALUES(PPIDM,PIDID,'IDID' ,PUSER,SYSDATE, 'UPD_ID',NULL,NULL );

                         EXCEPTION WHEN OTHERS THEN
                        VSALIDA := SQLERRM;
                      END;

               END IF;

       END IF;

END IF;

  dbms_output.put_line(' añ finlizxar  '|| VVALIDA  );

     RETURN(VSALIDA);


exception when others then

DBMS_OUTPUT.PUT_LINE('errror GRAL DE PIDID EN SPBPER Y GORADID:  '|| sqlerrm  );

END F_IDID;


END PKG_UPDATE_DATOS_SIU;
/

DROP PUBLIC SYNONYM PKG_UPDATE_DATOS_SIU;

CREATE OR REPLACE PUBLIC SYNONYM PKG_UPDATE_DATOS_SIU FOR BANINST1.PKG_UPDATE_DATOS_SIU;


GRANT EXECUTE ON BANINST1.PKG_UPDATE_DATOS_SIU TO PUBLIC;
