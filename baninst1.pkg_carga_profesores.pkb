DROP PACKAGE BODY BANINST1.PKG_CARGA_PROFESORES;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_CARGA_PROFESORES IS
--este pakete sirve para hacer la carga de los 
--para cargar estos datos
/*
SPAIDEN            SPRADDR            SPBPERS    SPRTELE        GOREMAL     SPRIDEN 
Matrícula    Apellido    Nombre    Dirección    colonia    CP    Fecha de nacimiento    Clave lada    Núm    Correo    Nombre legal
19848468    Sánchez/Tadeo    Verónica del Carmen    Calzada de la Naranaja No. 159 Int. Piso 4    Fracc Ind Alce Blanco    53370    01/01/2021    0155    55555555    tareasverosanchez@gmail.com    SANCHEZ TADEO VERONICA DEL CARMEN


created by Glovicx
date 26/03/021
*/
vl_error   VARCHAR2(1000):='EXITO';
VMATRICULA   VARCHAR2(12);

FUNCTION F_CREA_PIDM RETURN number is 


vpidm_u       INTEGER(8);
Vsalida       VARCHAR2(200);
--vperson       VARCHAR2(100);

 BEGIN
         
           vpidm_u := GB_COMMON.f_generate_pidm ();
           
           --DBMS_OUTPUT.PUT_LINE('crea el pidm'||vpidm_u);
           
     RETURN   vpidm_u;   
exception when others then
Vsalida := sqlerrm;
 return Vsalida;
--dbms_output.put_line ('salida error en crea ID_y pidm '||Vsalida);

end F_CREA_PIDM;


FUNCTION F_CREA_PERSONA(PPIDM NUMBER, PNOMBRE VARCHAR2, Papellido varchar2, PBDAY  VARCHAR2, PSEX VARCHAR2,pusuario varchar2 ) RETURN VARCHAR2  IS

VPIDM        NUMBER:=0;

--vl_error     VARCHAR2(200):= 'EXITO';

begin
-- VOY A CREAR EL PIDM 
--VPIDM  := F_CREA_PIDM;
vl_error   := 'EXITO';
--CALCULA LA MATRICULA
   BEGIN
       
            select max(SPRIDEN_ID)+1
            INTO VMATRICULA
            from spriden
            where 1=1
            and SPRIDEN_ENTITY_IND = 'P'
            and SPRIDEN_ID  like('0198%');
    
   
   Exception
        When Others then 
        vl_error := 'Error AL CREAR LA MATRICULA PKG_CARGA_PROFESORES'||sqlerrm;
        --DBMS_OUTPUT.PUT_LINE('ERR:'||vl_error );
    End;





--DBMS_OUTPUT.PUT_LINE('CALCULA IDMatricula:: '|| VMATRICULA );

         Begin
               Insert into spriden
                        (   SPRIDEN_PIDM,
                             SPRIDEN_ID,                                
                             SPRIDEN_LAST_NAME ,                        
                             SPRIDEN_FIRST_NAME ,                               
                             SPRIDEN_ACTIVITY_DATE,
                             SPRIDEN_SURROGATE_ID,
                             SPRIDEN_VERSION,                            
                             SPRIDEN_ENTITY_IND, 
                             SPRIDEN_USER,
                             SPRIDEN_DATA_ORIGIN,
                             SPRIDEN_SEARCH_LAST_NAME,
                             SPRIDEN_SEARCH_FIRST_NAME,
                             SPRIDEN_CREATE_DATE,
                             SPRIDEN_CREATE_USER
                             )                              
                   VALUES( PPIDM, '0'||VMATRICULA,Papellido,PNOMBRE,SYSDATE, NULL, 1,'P' ,pusuario,'CARGA_DOCENTES',replace(Papellido,'/',''), PNOMBRE, sysdate,'PKG_DOC' );             
               
         Exception
          When Others then 
         vl_error := 'Se presento un Error al insertar registro SPRIDEN:  '||sqlerrm;
          End;

--DBMS_OUTPUT.PUT_LINE('ya inserto spriden :: '|| VMATRICULA );

----se inserta la persona 
  BEGIN
    INSERT INTO SPBPERS
     (SPBPERS_PIDM,
        SPBPERS_ACTIVITY_DATE,
        SPBPERS_ARMED_SERV_MED_VET_IND,
        SPBPERS_SURROGATE_ID,
        SPBPERS_VERSION,
        SPBPERS_BIRTH_DATE,
        SPBPERS_LEGAL_NAME,
        SPBPERS_DATA_ORIGIN,
        SPBPERS_USER_ID,
        SPBPERS_SEX  
         )
       VALUES( PPIDM, SYSDATE, 'N', NULL, 1,TO_DATE(PBDAY,'DD/MM/YYYY'),replace(UPPER(Papellido),'/',' ')||' '|| UPPER(PNOMBRE) ,'CARGA_DOCENTES',pusuario,PSEX  );
    Exception
        When Others then 
        vl_error := 'Se presento un Error al insertar registro SPBPERS'||sqlerrm;
        End;

--DBMS_OUTPUT.PUT_LINE('ya inserto spbpers :: '|| PPIDM ||'->'|| vl_error);


IF vl_error = 'EXITO'  THEN

RETURN(vl_error);--REGRESO EL PIDM PARA QUE DEL LADO DE PYTHON LO RECIBAN Y PUEDAN LANZAR LAS DEMAS FUNCIONES CON ESE PIDM.

ELSE

RETURN(vl_error );

END IF;

exception when others then
null;
--DBMS_OUTPUT.PUT_LINE('error en persona paso 1 :: '|| vl_error );

return vl_error;


END F_CREA_PERSONA;


FUNCTION F_DIRECCION (ppidm  number,  PADDRESS  VARCHAR2, PCP VARCHAR2, PCOL VARCHAR2, PCITY  varchar2 , pusuario varchar2) RETURN VARCHAR2  IS



BEGIN
vl_error:='EXITO';

       -- SE INSERTA LA DIRECCION DEL PROFESOR
         INSERT INTO SPRADDR( SPRADDR_PIDM,
                            SPRADDR_ATYP_CODE,
                            SPRADDR_SEQNO,
                            SPRADDR_CITY,
                            SPRADDR_ACTIVITY_DATE,
                            SPRADDR_SURROGATE_ID,
                            SPRADDR_VERSION,
                            SPRADDR_STREET_LINE3,--COLONIA
                            SPRADDR_STREET_LINE1,--CALLE 
                            SPRADDR_ZIP,         --CP
                            SPRADDR_USER,
                            SPRADDR_DATA_ORIGIN )
         
         VALUES ( ppidm,'LA', 1, PCITY, SYSDATE, NULL, 1,PCOL, PADDRESS, PCP,pusuario,'CARGA_DOCENTES' );

        

IF vl_error = 'EXITO'  THEN

RETURN(vl_error);

ELSE

RETURN('ERROR EN DIRECION: '|| vl_error );

END IF;


EXCEPTION WHEN OTHERS THEN
 vl_error := 'Se presento un Error al insertar registro SPRADDR: '||sqlerrm;
RETURN( vl_error );

END F_DIRECCION;



FUNCTION F_MAILTEL  ( PPIDM NUMBER,PAREA  VARCHAR2, PPHONE  VARCHAR2 , PEMAIL VARCHAR2 ,pusuario  varchar2 )   RETURN VARCHAR2 IS


begin--------SE INSERTA TELEFONO
 vl_error:='EXITO';
 
         begin
           INSERT INTO SPRTELE ( 
            SPRTELE_PIDM,
            SPRTELE_SEQNO,
            SPRTELE_TELE_CODE,
            SPRTELE_ACTIVITY_DATE,
            SPRTELE_SURROGATE_ID,
            SPRTELE_VERSION,
            SPRTELE_PHONE_AREA,
            SPRTELE_PHONE_NUMBER,
            SPRTELE_DATA_ORIGIN,
            SPRTELE_USER_ID,
            SPRTELE_PRIMARY_IND
            )       
            VALUES(PPIDM, 1,'CELU', SYSDATE, NULL, 1, PAREA,PPHONE, 'CARGA_DOCENTES' ,pusuario ,'Y' );
            
            
         Exception
        When Others then 
        vl_error := 'Se presento un Error al insertar registro SPBPERS'||sqlerrm;
        End;


        BEGIN
             INSERT INTO GOREMAL
                           (GOREMAL_PIDM,
                            GOREMAL_EMAL_CODE,
                            GOREMAL_EMAIL_ADDRESS,
                            GOREMAL_STATUS_IND,
                            GOREMAL_PREFERRED_IND,
                            GOREMAL_ACTIVITY_DATE,
                            GOREMAL_USER_ID,
                            GOREMAL_DATA_ORIGIN,
                            GOREMAL_DISP_WEB_IND,
                            GOREMAL_SURROGATE_ID,
                            GOREMAL_VERSION  )
                  VALUES( PPIDM,'PRIN',PEMAIL,'A', 'Y', sysdate,pusuario,'CARGA_DOCENTES', 'Y', null, 1 );          
        
         Exception
        When Others then 
        vl_error := 'Se presento un Error al insertar registro GOREMAL'||sqlerrm;
        End;



IF vl_error = 'EXITO'  THEN

RETURN(vl_error);

ELSE

RETURN('ERROR EN: '|| vl_error );

END IF;


  Exception
When Others then 
vl_error := 'Se presento un Error al insertar registro SPRTELE,GOREMAL: '||sqlerrm;
RETURN vl_error;

END F_MAILTEL;


FUNCTION F_CNTR_DOCENTE(PPIDM NUMBER, PPERIODO VARCHAR2,PFCNT VARCHAR2, PCNTR VARCHAR2, PDEF VARCHAR2,pusuario varchar2   ) RETURN VARCHAR2 IS


BEGIN  
     vl_error:='EXITO';
   BEGIN
         INSERT INTO SIRICNT
         (SIRICNT_PIDM,
            SIRICNT_TERM_CODE_EFF,
            SIRICNT_ACTIVITY_DATE,
            SIRICNT_SURROGATE_ID,
            SIRICNT_VERSION,
            SIRICNT_FCNT_CODE,
            SIRICNT_CNTR_CODE,
            SIRICNT_DEF_IND,
            SIRICNT_USER_ID,
            SIRICNT_DATA_ORIGIN)
        VALUES(PPIDM, PPERIODO, SYSDATE, NULL, 1,PFCNT,PCNTR, PDEF, pusuario ,'CARGA_DOCENTES' );
   
    Exception
        When Others then 
        vl_error := 'Se presento un Error al insertar registro SIRICNT'||sqlerrm;
    End;



IF vl_error = 'EXITO'  THEN

RETURN(vl_error);

ELSE

RETURN('ERROR EN: '|| vl_error );

END IF;

Exception
When Others then 
vl_error := 'Error al insertar registro SIRICNT: '||sqlerrm;

RETURN vl_error;

END F_CNTR_DOCENTE;


FUNCTION F_CATEGO_DOCENTE(PPIDM NUMBER,PPERIODO VARCHAR2, PFCST VARCHAR2, PFCST_FECHA  VARCHAR2 , POVERR VARCHAR2, PFCTG VARCHAR2, PFSTP VARCHAR2 
                          ,PWKLD  VARCHAR2,PSCHD_IND  varchar2 , pfech_appoint varchar2,pusuario  varchar2 ) RETURN VARCHAR2 IS


BEGIN
vl_error := 'EXITO';

        BEGIN     
            INSERT INTO SIBINST (
                        SIBINST_PIDM,
                        SIBINST_TERM_CODE_EFF,
                        SIBINST_FCST_CODE,
                        SIBINST_FCST_DATE,
                        SIBINST_ACTIVITY_DATE,
                        SIBINST_OVERRIDE_PROCESS_IND,
                        SIBINST_SURROGATE_ID,
                        SIBINST_VERSION, 
                        SIBINST_FCTG_CODE,
                        SIBINST_FSTP_CODE,   
                        SIBINST_WKLD_CODE,
                        SIBINST_USER_ID,
                        SIBINST_DATA_ORIGIN,
                        SIBINST_SCHD_IND,
                        SIBINST_APPOINT_DATE
                        

                         )
            
            VALUES ( PPIDM,PPERIODO,PFCST, PFCST_FECHA, SYSDATE,POVERR, NULL, 1,PFCTG,PFSTP, PWKLD,pusuario,'CARGA_DOCENTES',PSCHD_IND ,TO_DATE(pfech_appoint,'DD/MM/YYYY' ) );
         Exception
        When Others then 
        vl_error := 'Se presento un Error al insertar registro SIBINST'||sqlerrm;
         END;


IF vl_error = 'EXITO'  THEN

RETURN(vl_error);

ELSE

RETURN('ERROR EN: '|| vl_error );

END IF;

Exception
When Others then 
vl_error := 'Error al insertar registro SIBINST: '||sqlerrm;

RETURN vl_error;


END F_CATEGO_DOCENTE;


FUNCTION F_DEPT_DOCENTE (PPIDM NUMBER, PPERIODO VARCHAR2,PCOLL VARCHAR2, PDEPT VARCHAR2, PPERCENT  VARCHAR2, pusuario varchar2   ) RETURN VARCHAR2 IS




BEGIN
vl_error :=  'EXITO';

       BEGIN
            INSERT INTO SIRDPCL ( 
                        SIRDPCL_PIDM,
                        SIRDPCL_TERM_CODE_EFF,
                        SIRDPCL_ACTIVITY_DATE,
                        SIRDPCL_SURROGATE_ID,
                        SIRDPCL_VERSION,
                        SIRDPCL_COLL_CODE,
                        SIRDPCL_DEPT_CODE,
                        SIRDPCL_PERCENTAGE,
                        SIRDPCL_USER_ID,
                        SIRDPCL_DATA_ORIGIN
                        )       
                  VALUES (PPIDM, PPERIODO, SYSDATE, NULL, 1, PCOLL, PDEPT,PPERCENT,pusuario,'CARGA_DOCENTES'  );
         Exception
        When Others then 
        vl_error := 'Se presento un Error al insertar registro SIRDPCL'||sqlerrm;          
       END;


IF vl_error = 'EXITO'  THEN

RETURN(vl_error);

ELSE

RETURN('ERROR EN: '|| vl_error );

END IF;

Exception
When Others then 
vl_error := 'Error al insertar registro SIRDPCL: '||sqlerrm;

RETURN vl_error;


END F_DEPT_DOCENTE;


FUNCTION FCARGA_DOC (papellido varchar2, pnombre varchar2, pdirecion varchar2, pcolonia varchar2, pcp varchar2, pcity varchar2, pclave varchar, pnumero varchar2, 
                     pmail varchar2, pbday  varchar2 , psex varchar2, pfech_appoint varchar2, pusuario  varchar2 ,pcatego  varchar2) RETURN VARCHAR2 IS

--Apellido    Nombre    Dirección    colonia    CP    Ciudad    Clave lada    Núm    Correo    Fecha de nacimiento
VSALIDA  VARCHAR2(200);

VPIDM  NUMBER:=0;
vvalida_email   varchar2(1):='N';

BEGIN
VSALIDA := 'EXITO';

-- 1.--  validamos que no exista el mail del profesor si ya existe se regresa el error que existe si no existe emtonces se crea nuevo

    begin
         
       select DISTINCT  'Y', F_GetSpridenID(GO.GOREMAL_PIDM)
        INTO  vvalida_email,VMATRICULA
        from gOREMAL go 
        where 1=1
        AND GO.GOREMAL_STATUS_IND  = 'A'
        and TRIM(GOREMAL_EMAIL_ADDRESS) = trim(pmail);
    
      --dbms_output.put_line('matricula del profe:  '|| vvalida_email );
     
    exception when TOO_MANY_ROWS then
    vvalida_email := 'Y';
    
    --dbms_output.put_line('matricula del profeXXX:  '|| vvalida_email );
    
       BEGIN
        select DISTINCT  MAX(F_GetSpridenID(GO.GOREMAL_PIDM) )
        INTO  VMATRICULA
        from gOREMAL go 
        where 1=1
        AND  GO.GOREMAL_STATUS_IND  = 'A'
        and TRIM(GOREMAL_EMAIL_ADDRESS) = trim(pmail)
        AND ROWNUM < 2;
      EXCEPTION WHEN OTHERS THEN
       VMATRICULA := NULL;
       --dbms_output.put_line('ESTOY EN LA DOBLE EXCEPTIONAAA:  '|| VMATRICULA );
      END;
    
    
    WHEN OTHERS THEN
    
    vvalida_email   :='N';
      --dbms_output.put_line('no EXISTE matricula del profe:  '|| vvalida_email );
    end;

  

IF vvalida_email = 'Y'  THEN
--DBMS_OUTPUT.PUT_LINE('YA EXISTE EL MAIL:  '||vvalida_email );

RETURN('EL MAIL YA EXISTE|'||VMATRICULA );

ELSE

--DBMS_OUTPUT.PUT_LINE('NO EXISTE EL MAIL SE CREA NUEVO'||vvalida_email );

-- 1.-  PRIMERO CREAMOS EL PIDM

 VPIDM := F_CREA_PIDM;
 
-- 2.-- CREAMOS LA PERSONA 
  VSALIDA := F_CREA_PERSONA(VPIDM, PNOMBRE, Papellido, PBDAY, PSEX,pusuario );
--DBMS_OUTPUT.PUT_LINE('SE CREO EL PIDM Y MATRICULA: '|| VPIDM ||'-'|| VSALIDA );

IF VSALIDA = 'EXITO'  THEN 
-- 3.--  CREA LA DIRECCION--
  VSALIDA := F_DIRECCION (VPIDM,  pdirecion, PCP, pcolonia, PCITY,pusuario );
  --DBMS_OUTPUT.PUT_LINE('SE CREO LA DIRECCION: '|| VSALIDA );
END IF;

IF VSALIDA = 'EXITO'  THEN 
-- 4.--  CREA MAIL Y TEL --
  VSALIDA := F_MAILTEL  ( VPIDM ,pclave  , pnumero , pmail,pusuario );
  --DBMS_OUTPUT.PUT_LINE('SE CREO LA EMAIL Y CEL '|| VSALIDA );
END IF;

------AQUI EMPIEZAN LOS INSERT CON CODIGOS DUROS----SEGUN LAYOUT DE AMERICA
IF VSALIDA = 'EXITO'  THEN 
-- 4.--  CREA SIRINCT --
  VSALIDA := F_CNTR_DOCENTE(VPIDM , '000000' ,NULL , NULL, 'D' ,pusuario   );
  --DBMS_OUTPUT.PUT_LINE('SE CREO LA SIRINCT: '|| VSALIDA );
END IF;

IF VSALIDA = 'EXITO'  THEN 
-- 5.-- CREA SIRDPCL  --
/*
SIRDPCL_COLL_CODE    SIRDPCL_DEPT_CODE    SIRDPCL_PERCENTAGE    SIRDPCL_TERM_CODE_EFF
Escuela                  Departamento       Porcentage                Periodo
SE                           0000               100                  000000

*/

  VSALIDA := F_DEPT_DOCENTE (VPIDM , '000000' ,'SE' , '0000' , '100' ,pusuario    );
  --DBMS_OUTPUT.PUT_LINE('SE CREO LA SIRDPCL  '|| VSALIDA );
END IF;


IF VSALIDA = 'EXITO' and pcatego != 'S/C' THEN 
-- 6.--  CREA SIBINST --
--SIBINST_FCST_CODE    SIBINST_SCHD_IND    SIBINST_FCTG_CODE    SIBINST_FSTP_CODE    SIBINST_WKLD_CODE    SIBINST_TERM_CODE_EFF    SIBINST_FCST_DATE    SIBINST_OVERRIDE_PROCESS_IND
--Estatus_Doc          ROL _Docente           CATEGORIA          Estatus_Docente      Rgl Cargo Trab            Periodo               Fecha    
--AC                          Y                 DTNA                  AC                  DPHOP                 000000                 SYSDATE                N


  VSALIDA := F_CATEGO_DOCENTE(VPIDM ,'000000' , 'AC' , SYSDATE   , 'N' , pcatego , 'AC','DPHOP','Y',pfech_appoint,pusuario );
  --DBMS_OUTPUT.PUT_LINE('SE CREO LA SIBINST  '|| VSALIDA );
END IF;


END IF;

IF VSALIDA = 'EXITO'  THEN
COMMIT;
--DBMS_OUTPUT.PUT_LINE('SE creo todo el registro limpio  '|| VSALIDA );
return('0'||VMATRICULA);


ELSE
ROLLBACK;
--DBMS_OUTPUT.PUT_LINE('HUBo un error en la carga  '|| VSALIDA );
return(VSALIDA);


END IF;


exception when others then

VSALIDA := 'ERROR GRAL FCARGA_DOC: '||sqlerrm;
  --DBMS_OUTPUT.PUT_LINE('ERROR GRAL. '|| VSALIDA );
  return(VSALIDA);

END FCARGA_DOC;


FUNCTION F_BAJA_PROFESOR (PMATRICULA VARCHAR2, PFCST VARCHAR2, PAPPOINT VARCHAR2, PUSUARIO VARCHAR2 ) RETURN VARCHAR2 IS

VSALIDA VARCHAR2(200):='EXITO';

BEGIN

   BEGIN
                
        UPDATE SIBINST
        SET 
        SIBINST_FCST_CODE      = PFCST,
        SIBINST_FCST_DATE      = TO_DATE(PAPPOINT,'DD/MM/YYYY') ,
        SIBINST_USER_ID        = PUSUARIO  ,
        SIBINST_ACTIVITY_DATE  = SYSDATE
        where 1=1
        and SIBINST_PIDM = FGET_PIDM(PMATRICULA);
        
   EXCEPTION WHEN OTHERS THEN
   VSALIDA := 'ERROR AL DAR DE BAJA AL PROFESOR SIBINST';
   
   END;


COMMIT;

RETURN( VSALIDA );


VSALIDA := 'ERROR GRAL FBAJA_PROFESOR: '||sqlerrm;
  --DBMS_OUTPUT.PUT_LINE('ERROR GRAL. '|| VSALIDA );
  return(VSALIDA);

END F_BAJA_PROFESOR;

END PKG_CARGA_PROFESORES;
/

DROP PUBLIC SYNONYM PKG_CARGA_PROFESORES;

CREATE OR REPLACE PUBLIC SYNONYM PKG_CARGA_PROFESORES FOR BANINST1.PKG_CARGA_PROFESORES;


GRANT EXECUTE ON BANINST1.PKG_CARGA_PROFESORES TO PUBLIC;
