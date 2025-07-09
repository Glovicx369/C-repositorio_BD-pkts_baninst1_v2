DROP PACKAGE BODY BANINST1.PKG_MSJ_SIU;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_MSJ_SIU IS
/*
CREATED: GLOVICX
DATE:     11/08/2020
DETAILS: ESTE PKT SIRVE PARA EL PROCESOS DE MENSAJES AUTOMATICOS EN SIU.

*/

FUNCTION F_MORAS_MSJ (ppidm number)
return  BANINST1.PKG_MSJ_SIU.dmoras_type

IS
/*
CREATE : GLOVICX
PURPOSE:    SE UTILIZA PARA MOSTRAR UNA PANTALLA EMERGENTE EN SIU DASHBOARD, A LOS ALUMNOS QUE CUMPLAN ESTAS CARACTERISTICAS
Este mensaje solamente deberá de mostrarse para alumnos cuyo saldo sea mayor
México, >=  $3,000.00 >>> 'UTL' 
Chile  >=  $1200,00.00, >>>'CHI' 
Perú >= $540.00          >>> 'PER'
Colombia>=   $555,000.00. >> 'COL'
ESTOS MONTOS SE PARAMETRIZAN PARA QUE NO QUEDEN EL CODIGO DURO
*/
vtmora varchar2(20);
vsaldo   number:= 0;
VSALIDA  VARCHAR2(800);
VSALDO_MIN   NUMBER:=0;
VCAMPUS       VARCHAR2(4);
vnivel         VARCHAR2(4);
vprograma VARCHAR2(14);
cur_moras    BANINST1.PKG_MSJ_SIU.dmoras_type;

begin
null;

    begin
    select pkg_reportes.f_mora(ppidm)
      into  vtmora
    from dual;
    exception when others then
       vtmora := 'NA';
    end;

    begin
    select pkg_reportes.f_saldototal(ppidm)
      into  vsaldo
    from dual;
    exception when others then
           vsaldo := 0;
    end;
    
    BEGIN
    
            SELECT DISTINCT CAMPUS,NIVEL,PROGRAMA
                INTO VCAMPUS, VNIVEL, VPROGRAMA
            FROM TZTPROG T1
            WHERE T1.PIDM = ppidm
            AND T1.SP = ( SELECT MAX(T2.SP)  FROM TZTPROG  T2 WHERE 1=1 AND T2.PIDM =  T1.PIDM )
            ;
            
     EXCEPTION WHEN OTHERS THEN
       VCAMPUS  := NULL; 
       VNIVEL   := NULL;
       VPROGRAMA  := NULL;
    END;
    
--    ----EVALUES LAS CONDIONES DE SALDOS MINIMOS PARA PRESENTAR MENSAJE O NO
--    BEGIN
--                  
--            SELECT  ZSTPARA_PARAM_VALOR,ZSTPARA_PARAM_ID
--              INTO   VSALDO_MIN, VCAMPUS
--            FROM ZSTPARA
--            WHERE 1=1 
--            AND ZSTPARA_MAPA_ID = 'VMORAS'
--            AND ZSTPARA_PARAM_ID  = pcampus;
--     exception when others then
--           VSALDO_MIN := 0;
--           VCAMPUS      := 'NA';
--    END;
--    
--      IF VCAMPUS = pcampus  AND  vsaldo >= VSALDO_MIN THEN 
--       --SI EL SALDO DEL ALUMNO ES MAYOR QUE EL PARAMETRIZADOR SI PRESENTA MENSAJE
--       VSALIDA := 'Alumno Tiene: '|| vtmora ||'; adeudo $ '|| TO_CHAR(vsaldo,'999,999,999.00') ;
--       ELSE
--           --MANDA EXITO SIGNIFINCA QUE EL SALDIO ES MENOR Y NO HAY VENTANA EMERGENTE 
--       VSALIDA := 'EXITO' ;
--     END IF;
--
     VSALIDA := 'Alumno Tiene: '|| vtmora ||'; adeudo $ '|| TO_CHAR(vsaldo,'999,999,999.00') ;
     
dbms_output.put_line(VSALIDA );
dbms_output.put_line('ADEUDO '|| vsaldo );
      begin
      
          open cur_moras for  SELECT  VCAMPUS as campus,VNIVEL as nivel,VPROGRAMA as programa,
          vtmora as moras,TO_CHAR(vsaldo,'999,999,999.00') as saldo
                                                FROM  DUAL;
          
          
      return (cur_moras);
      
      exception when others then
      null;
      VSALIDA:= SQLERRM;
      RETURN cur_moras;
      end;
 

end;

FUNCTION F_MORAS_MSJES (ppidm number)
return  varchar2 --BANINST1.PKG_MSJ_SIU.dmoras_type

IS
/*
CREATE : GLOVICX
PURPOSE:    SE UTILIZA PARA MOSTRAR UNA PANTALLA EMERGENTE EN SIU DASHBOARD, A LOS ALUMNOS QUE CUMPLAN ESTAS CARACTERISTICAS
Este mensaje solamente deberá de mostrarse para alumnos cuyo saldo sea mayor
México, >=  $3,000.00 >>> 'UTL' 
Chile  >=  $1200,00.00, >>>'CHI' 
Perú >= $540.00          >>> 'PER'
Colombia>=   $555,000.00. >> 'COL'
ESTOS MONTOS SE PARAMETRIZAN PARA QUE NO QUEDEN EL CODIGO DURO
*/
vtmora varchar2(20):='00000';
vsaldo   number:= 0;
VSALIDA  VARCHAR2(800);
--VSALIDA  VARCHAR2(800);
VSALDO_MIN   NUMBER:=0;
VCAMPUS       VARCHAR2(4);
vnivel         VARCHAR2(4);
vprograma VARCHAR2(14);
--cur_moras    BANINST1.PKG_MSJ_SIU.dmoras_type;

begin
null;

    begin
    select pkg_reportes.f_mora(ppidm)
      into  vtmora
    from dual;
    exception when others then
       vtmora := '00000';
    end;

    begin
    select pkg_reportes.f_saldototal(ppidm)
      into  vsaldo
    from dual;
    exception when others then
           vsaldo := 0;
    end;
    
    BEGIN
    
            SELECT DISTINCT CAMPUS,NIVEL,PROGRAMA
                INTO VCAMPUS, VNIVEL, VPROGRAMA
            FROM TZTPROG T1
            WHERE T1.PIDM = ppidm
            AND T1.SP = ( SELECT MAX(T2.SP)  FROM TZTPROG  T2 WHERE 1=1 AND T2.PIDM =  T1.PIDM )
            ;
            
     EXCEPTION WHEN OTHERS THEN
       VCAMPUS  := NULL; 
       VNIVEL   := NULL;
       VPROGRAMA  := NULL;
    END;
    
    -- si mora viene vacia le agrega ceros
    IF vtmora is null then
      dbms_output.put_line('la mora esta vacia,'||vtmora);
        vtmora:= '00000';
        ELSE
        NULL;
      END IF;
    
------------------------VA A CALCULAR EL IMPORTE DEL MONTO------DE DEUDA
vsaldo := BANINST1.PKG_MSJ_SIU.f_cal_monto(ppidm);

dbms_output.put_line(VCAMPUS||','||VNIVEL||','||VPROGRAMA||','||vtmora||','||vsaldo);
  vsalida := VCAMPUS||','||VNIVEL||','||VPROGRAMA||','||vtmora||','||vsaldo;

 RETURN (VSALIDA);
 exception when others then
      null;
      VSALIDA:= SQLERRM;
      RETURN VSALIDA;
end;

function f_cal_monto  ( ppidm number) return number is

v_cur SYS_REFCURSOR;
vsalida   varchar2(100);
v1  varchar2(60);
v2  varchar2(60);
v3  varchar2(60);
v4  varchar2(60);
v5  varchar2(60);
v6  varchar2(60);
v7  varchar2(60);
v8  varchar2(60);
v9  varchar2(60);
v10  varchar2(60);
v11  varchar2(60);
v12  varchar2(60);
vsuma_total  number:=0 ;
begin

v_cur := PKG_FINANZAS.F_CARGOS_OUT(ppidm);

  LOOP
    FETCH v_cur INTO v1, v2, v3,v4,v5,v6,v7,v8,v9,v10,v11,v12;
    EXIT WHEN v_cur%NOTFOUND;
   
    
  --  IF  v11 in ('COL','VTA') and v9 = 'VENCIDO' then  ---  se quita para que mande el gran total asi lo pidio kareem
    IF    v9 in  ('VENCIDO', 'PAGO PARCIAL VENCIDO')  and  v11 in ('COL','VTA') then 
    
    vsuma_total  := vsuma_total + v5;
     dbms_output.put_line(v1 || ' ' || v2||'-'|| v5||'-'||v9);
    end if;
    
    
  END LOOP;
  CLOSE v_cur;
RETURN vsuma_total;

exception when others then
      null;
      VSALIDA:= SQLERRM;
      RETURN VSALIDA;
end;

BEGIN
NULL;


END PKG_MSJ_SIU;
/

DROP PUBLIC SYNONYM PKG_MSJ_SIU;

CREATE OR REPLACE PUBLIC SYNONYM PKG_MSJ_SIU FOR BANINST1.PKG_MSJ_SIU;


GRANT EXECUTE ON BANINST1.PKG_MSJ_SIU TO PUBLIC;
