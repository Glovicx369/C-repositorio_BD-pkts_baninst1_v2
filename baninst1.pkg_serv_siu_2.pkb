DROP PACKAGE BODY BANINST1.PKG_SERV_SIU_2;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_SERV_SIU_2  AS
/*
PAQUETE para la  contratación de servicios (Accesorios)  desde SIU,version2
esta nueva version se hace para subir los procesos y funciones complementarias del auto servicio
creado x glovicx  19.03.2025

*/
FUNCTION F_COTE_SS (PPIDM NUMBER,  PCODE  VARCHAR ) RETURN varchar
IS

/* ESTA Función se hizo para hacer la validación del alumno que cumpla con el SS o las caracteristicas 
necesarias para comprar un acceosrio de COTE y CAPS  glovicx 19.03.2025
esta función se ejecuta desde python al momento de comprar el accesorio glovicx 23.04.2025

*/
vvalidax     number:= 0;
vcote        varchar2(8):='XX';
vestatus     varchar2(3);
VNIVEL       varchar2(4);
vcampus      varchar2(4);
VAVANCE      number:= 0;
VSSO         varchar2(1):= 'N';
VSALIDA      VARCHAR2(600):= 'EXITO';
vingreso     varchar2(4);
vcaps        varchar2(8):='XX';
vfoto        varchar2(4):= 'Y';
VESTATUS_foto varchar2(4):= 'SI';
vprograma     varchar2(12);


BEGIN

---- primero buscamos nivel y campus, estatus
     begin
     
        select distinct  T.NIVEL, T.CAMPUS, t.estatus,  t.TIPO_INGRESO, t.programa
           into  VNIVEL, vcampus, vestatus, vingreso, vprograma 
            from tztprog t
                where 1=1
                  and T.ESTATUS not in ('CV','CP' )
                  and t.pidm = PPIDM
                  and t.SP = ( select max(t2.SP)   
                                  from  tztprog t2
                                   where 1=1
                                     and t.pidm    = t2.pidm 
                                     ); 
                  
                 

     exception when others then
          VNIVEL   := null;
          vcampus  := null;
          vestatus := null;
          vingreso := null;
          vprograma := null;

      end;
     
     DBMS_OUTPUT.PUT_LINE('despues de tztprog'||PPIDM ||'-'|| vcampus ||'-'|| VNIVEL||'-'|| vestatus ||'-'||vingreso ||'-'|| vprograma  );
    --- buscamos el avance--
         BEGIN
          
             VAVANCE :=0;
             
                   SELECT ROUND(nvl(SZTHITA_AVANCE,0))
                      INTO VAVANCE
                        FROM SZTHITA ZT
                        WHERE 1=1
                        and   ZT.SZTHITA_PIDM   = PPIDM
                        AND   ZT.SZTHITA_LEVL  = VNIVEL
                        AND   ZT.SZTHITA_PROG   = VPROGRAMA  ;
                        
                        ----dbms_output.PUT_LINE('SALIDA AVANCE HITA  '|| VDESC2);
          EXCEPTION WHEN OTHERS THEN
              
                        BEGIN
                           SELECT ROUND(BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 ( PPIDM, vPROGRAMA ))
                                  INTO VAVANCE
                             FROM DUAL;

                          --   --dbms_output.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
                          EXCEPTION WHEN OTHERS THEN
                           VAVANCE :=0;
                          END;
          END;
       
         
       IF VAVANCE > 100 then
           VAVANCE := 100;
       END IF;
       
      BEGIN
            select distinct 'Y'
              INTO VSSO
                from SHRNCRS R
                where 1=1
                AND R.SHRNCRS_PIDM = PPIDM
                AND R.SHRNCRS_NCST_CODE = 'AP'
                AND R.SHRNCRS_NCRQ_CODE = 'SS';
                
       exception when others then
       VSSO := 'N';
       
         dbms_output.put_line('ERROR EN SERVICIO SOCIAL  '|| VSSO );
       END;
       
         begin
               
             select distinct 'SI' 
                  INTO VESTATUS_foto
              from sarchkl kl   
                where 1=1 
                 and kl.SARCHKL_PIDM = PPIDM
                 AND kl.SARCHKL_ADMR_CODE  =  'FCPD'
                 and kl.SARCHKL_CKST_CODE in (select ZSTPARA_PARAM_VALOR
                                                from ZSTPARA z1
                                                where 1=1
                                                and z1.ZSTPARA_MAPA_ID = 'COMPRA_DOCA'
                                                and z1.ZSTPARA_PARAM_ID =  'FCPD' );
            

         exception when others then
            VSALIDA := SQLERRM;
            VESTATUS_foto := 'NO';
          end;


        dbms_output.put_line('LOS PARAMETROS DE inicion :  '|| PPIDM||'-'|| VSALIDA ||'->'|| VESTATUS_foto );
         
     
      
    IF PCODE = 'CAPS'   THEN
    
      vcaps  := 'CAPS'  ;
      /*
         Para alumnos del campus UTL y LATAM, nivel LI, estatus matriculado (MA), con 70% de avance curricular en adelante 
         y para alumnos EG, con 100% de avance curricular.
        - Tipo de ingreso: RE, RV, EQ y DT.
     - El accesorio solo debe mostrarse en el autoservicio siempre y cuando los alumnos 
       matriculados tengan un 70% de avance en adelante y, 
       para los egresados cuando se encuentre liberado el SS (AP).
      */
        
     dbms_output.put_line('LOS PARAMETROS alumno :  '|| PPIDM||'-'|| VNIVEL ||'->'|| vingreso||'-'|| vestatus||'-'|| VAVANCE||'-'|| VSSO||'-'|| vcaps );
           
         IF  VNIVEL = 'LI' and vcampus = 'UTL' and vingreso in ('RE','EQ','RV','DT')  THEN 
           null;
           
              IF vestatus = 'MA' and VAVANCE >= 70   then
               
               vcaps  := 'XX';-- como si cumple SI se presenta en la tienda
               
              ELSIF vestatus = 'EG' and VSSO = 'Y' and VAVANCE >= 100   then 
               vcaps  := 'XX';-- como si cumple SI se presenta en la tienda
               
              end if;
          dbms_output.put_line('validaciones UTL --LI :  '|| PPIDM||'-'|| vestatus ||'->'|| VAVANCE||'-'||vcaps );
         
         ELSIF   VNIVEL = 'LI' and vcampus != 'UTL' and vingreso in ('RE','EQ','RV','DT')  THEN -- LATAM 
         
            IF vestatus = 'MA' and VAVANCE >= 70   then
               
               vcaps  := 'XX';-- como si cumple SI se presenta en la tienda
            
            ELSIF  vestatus = 'EG'  and VAVANCE < 100 then 
            
                 vcaps  := 'CAPS';--NO cumple NO se presenta en la tienda
               
            ELSIF vestatus = 'EG'  and VAVANCE >= 100   then 
               vcaps  := 'XX';-- como si cumple SI se presenta en la tienda
               
             end if;
         
         dbms_output.put_line('validaciones UTL --LATAM :  '|| PPIDM||'-'|| vestatus ||'->'|| VAVANCE||'-'||vcaps );
         end if;
         
          
       dbms_output.put_line('DESPUES::: de validaciones :  '|| PPIDM||'-'|| VSALIDA ||'->'|| VESTATUS_foto );
        
         IF VESTATUS_foto = 'NO' THEN
         
           VSALIDA := 'No cuentas con la fotografía Carta Pasante Digital validada'; 
             
             dbms_output.put_line('ENTRA Al Else de la foto '|| vfoto );
         
         ELSIF  vcaps = 'CAPS'  AND VCAMPUS = 'UTL' then
  
          vsalida := 'Servicio social pendiente de liberación';
       
          dbms_output.put_line('sin serv social:  '|| PPIDM||'-'|| VSALIDA ||'->'|| vcaps );
          
         ELSIF   vcaps = 'CAPS' AND VCAMPUS != 'UTL' AND ( VSSO = 'N' OR VAVANCE < 100)  then
          
          vsalida := ' No cumplen con los requisitos';
            dbms_output.put_line('sin serv social:  '|| PPIDM||'-'|| VSALIDA ||'->'|| vcaps );
            
         else
         
          vsalida := 'EXITO';
          
          dbms_output.put_line('en el  ELSE CAPS :  '|| PPIDM||'-'|| VSALIDA ||'->'|| vcaps );
          
         end if;
            
     ELSE    --aqui va COTE
     
       dbms_output.put_line('Antes de validaciones COTE :  '|| PPIDM||'-'|| VSALIDA ||'->'|| vcote||'-'|| VSSO||'-'|| vestatus ||'-'||VAVANCE  );
     
      IF VSSO = 'N' and VNIVEL = 'LI' and  vcampus = 'UTL' THEN ---NO CUMPLE  se anexa esa misma regla del ss para los COTE glovicx 19.03.2025
      
          vcote := 'COTE';
           
           dbms_output.put_line('en el  ELSE COTE SS = NO, campus UTL :  '|| PPIDM||'-'|| vcote ||'->'|| vcote||'-'|| VSSO||'-'|| vestatus ||'-'||VAVANCE  );
                        
       ELSIF  VSSO = 'N'  and  vcampus != 'UTL' and VAVANCE < 100 THEN --NO CUMPLE
       /*    Para los alumnos de LATAM LI, solo deben tener estatus de EG, con el 100% de avance curricular.*/
        vcote := 'COTE';
       dbms_output.put_line('en el  ELSE COTE SS = NO campus LATAM :  '|| PPIDM||'-'|| vcote ||'->'|| vcote||'-'|| VSSO||'-'|| vestatus ||'-'||VAVANCE  );
       
       ELSIF VAVANCE >= 100 and vestatus = 'EG'  then -- aquiSI CUMPLE - caen todos lo latam Y UTS si sumple con las reglas
         vcote := 'XX';
         dbms_output.put_line('CON  ELSE COTE SS  :  '|| PPIDM||'-'|| vcote ||'->'|| vcote||'-'|| VSSO||'-'|| vestatus ||'-'||VAVANCE  );
         
       
       else   -- NO cumple y se oculta en la tienda
      
  
       vcote   := 'COTE';
       dbms_output.put_line('Ultimo  ELSE COTE SSXX3   :  '|| PPIDM||'-'|| vcote ||'->'|| vcaps||'-'|| VSSO||'-'|| vestatus ||'-'||VAVANCE  );
       
       END IF;

      
      IF  vcote = 'COTE' and VNIVEL = 'LI' AND  VSSO = 'N' AND vcampus = 'UTL'  then
  
          vsalida := 'Servicio social pendiente de liberación';
          
      ELSIF  vcote = 'COTE' and VNIVEL in ('MA', 'LI')  then
      
       vsalida := 'No cumple con los requisitos';
       
       

      else
          vsalida := 'EXITO';
          
      end if;

     
     
    END IF;
 
     
      
      
  RETURN (vsalida);


exception when others then
vsalida := sqlerrm;
 
 RETURN (vsalida);
dbms_output.put_line('ERROR GRAL CAPS, COTE :  '|| PPIDM||'-'|| VSALIDA ||'->'|| vcaps||'-'|| VSSO||'-'|| vestatus ||'-'||VAVANCE  );
     
end F_COTE_SS;


end PKG_SERV_SIU_2;
/

DROP PUBLIC SYNONYM PKG_SERV_SIU_2;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SERV_SIU_2 FOR BANINST1.PKG_SERV_SIU_2;


GRANT EXECUTE ON BANINST1.PKG_SERV_SIU_2 TO PUBLIC WITH GRANT OPTION;
