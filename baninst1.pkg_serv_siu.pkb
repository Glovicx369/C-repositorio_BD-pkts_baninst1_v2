DROP PACKAGE BODY BANINST1.PKG_SERV_SIU;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_SERV_SIU  AS
/*
PAQUETE para la  contratación de servicios (Accesorios)  desde SIU,
********** create by glovicx, 09/04/2019 *********
----------ultima modificacion el producion 19/07/2019-----
--------última versión liberada 10/09/2019   se agrega la parte de insertar horario y cancelación  de nivelación--
--------version final----
--SE AGREGA UNA BANDERA al proceso que recupera las materias reprobadas de nivelacion para los casos de MA y MS que 6.0 es reprobada. glovicx 07-10-2019

se agrega al parametrizador de las monedas para que tome segu su campus, para colombia y peru.
glovicx 11/10/2019
-------
se realizan cambios en la función de consulta de servicios para ajustar "pagado", "cancelado"
se hacen ajustes en la función de inserta horario para que al final si todo salio bien entonces vaya a la cartera y obtenga el no_recibo
para  actualizar en sfrstcr. para devengo  glovicx 27/11/2019.
--nuevos ajuste para la parte de las cancelaciones y los descuentos liberado a prod el dia 25/02/2020 glovicx

--cambios para los descuentos preventas ad liberado 12/05/2020  glovicx
-- se hace el cambio en el proceso de F_PRECIO_MATERIA_NIVE para calcular el programa por si tiene 2 o mas programas
en esttus de CP solo toma el ultimo glovicx 08/09/2020
--nueva version contine proceso de extr y tisu para la universidad Unica  glovicx 01/12/2020
--  CAMBIAS SE GAREGAN LAS MODIFICACIONES PARA VENDER UPSELLING( LOS CURSOS PARA SEMI-PRESENCIALES) GLOVICX CAMBIOS EN LOS PARTES DE PERIODO 12/01/2021
 --se agrega la funcionalidad de las 2 nuevas columnas para las nivelaciones tekf y mail.
 --se gregan la funcionalidad para la venta de COLF diferida para todos los campues.glovicx 16/03/021
 -- SE LIBERAN CAMBIOS PARA EXTR  de universidad insurgentes glovicx 19/05/2021
 -- se liberan ajuste  PARA EXTR  de universidad insurgentes glovicx 04/06/2021
 -- se libera COLF X NIVEL glovicx 03/08/0221
 -- libera cambio en cancela_serv se cambia el mensaje para el alumno glovicx 26/11/021
-- SE AGREGA LA FUNCIONALIDDA DE Utelx
 SE AGREGA LA FUNCIONALIDDA DE UNICEF glovicx 17/01/022--
 SE AGREGA LA FUNCIONALIDAD DE VOXY GLOVICX 14/04/022
 SE AGREGA LA FUNCIONALIDAD DE COSTO CERO QE  glovicx 16.08.022
 SE LIBERA NUEVA FUNCIONALIDAD DE NIVES SOBRE TABLA SZTNIPR GLOVICX 06.09.022
  se libera nueva version de nuevas certificaciones glovicx 13.09.022
se libera ajuste de envios ENIN glovicx 20.12.2024
se agrean ajuste de nivecero v3 y cientifica 20.03.2025 glovicx 
*/

 vl_error varchar2(2500);
 vcode_curr        varchar2(3);
  TYPE t_Cursor IS REF CURSOR;

FUNCTION F_TIENDA_SOLIC (P_PIDM IN NUMBER) RETURN PKG_SERV_SIU.cursor_out_tienda
           AS
                c_out_tienda PKG_SERV_SIU.cursor_out_tienda;
vl_error     varchar2(500);

vserv     VARCHAR2(5):='XX';
vserv2    VARCHAR2(5):='XX';
vserv3    varchar2(5):='XX';
vserv4    VARCHAR2(8):= 'XX';
vprograma varchar2(15):= NULL;
vnivel    varchar2(5):= null;
vcampus   varchar2(5):= null;
vperiodo  varchar2(30);
vnum_periodo  number:=0;
vstudy        number:=0;
VMIN          NUMBER:= 0;
VMAX          NUMBER:= 0;


 BEGIN

 ---vamos a validar si el alumno ya tiene el servicio de sesiones ejecutivas entonces ya no se lo presente en el tapiz de compras --glovicx 15/01/2021

   begin
           SELECT distinct decode(substr(SZTALOL_PROGRAMA,4,2),'LI','SEJL','MA','SEJM') SERVICIO
               into vserv
             FROM sztalol
                where 1=1
                and SZTALOL_PIDM = P_PIDM
                  and SZTALOL_ESTATUS = 'A';
        --si esta con estatus "A" no muestars fechas  regla de fernando
   exception when others then
        vserv := 'XX';
    end;

   --si esta con estatus "A" no muestars fechas  regla de fernando

--    insert into twpasow(valor1, valor2, valor3)
--    values ( 'upsellingMENU-INI_NEW', P_PIDM,vserv);
--    commit;
      BEGIN

        select distinct NVL(DECODE(T1.NIVEL, 'LI', 'CELI', 'MA','CEMA', 'MS','CEMS'),'XX') acceso
        INTO vserv2
        from tztprog t1, sztdtec Z1
        where 1=1
        AND T1.PROGRAMA  = Z1.SZTDTEC_PROGRAM
        and SZTDTEC_MOD_TYPE != 'S' --CON ESTA NEGACION VALIDAMOS TODOS LOS ALUMNOS QUE NO ESTEN EN UN PROGRAMA DE SEMIS
        AND T1.PIDM = P_PIDM
         ;

       exception when others then
        vserv2 := 'XX';
      END;

      -------opciones para ver enque cuatrimestre o bimentre se encuentra el alumno y con eso se determina
      ----- si se presenta o no el servicio  de COLI

          begin

               select distinct t.programa,t.nivel, t.campus, T.SP
                   INTO vprograma , vnivel, vcampus, vstudy
                from tztprog t
                 where 1=1
                  and  t.pidm = P_PIDM
                  and t.sp = ( select max(t2.sp) from tztprog t2
                               where 1=1
                                and t2.pidm = t.pidm);


                ----dbms_output.PUT_LINE('despues de nivel SEJM:'||vprograma||'-'||  vnivel );
           EXCEPTION WHEN OTHERS THEN

                begin
                   select SORLCUR_PROGRAM, SORLCUR_LEVL_CODE, SORLCUR_CAMP_CODE
                      INTO vprograma , vnivel, vcampus
                    from sorlcur s1
                   where 1=1
                   and sorlcur_pidm = P_PIDM
                   and SORLCUR_SEQNO = (select max (SORLCUR_SEQNO)  from sorlcur s2
                                            where 1=1
                                              and s1.sorlcur_pidm = s2.sorlcur_pidm  );


                  EXCEPTION WHEN OTHERS THEN
                    vprograma := NULL;
                    vnivel    := null;
                    vcampus   := null;
                    vstudy    := NULL;

                  end;


          END;

        ------aqui hay que hacer la subrutina para saber el numero de cuatrimestre que esta
        -- regla de fernando 29/09/021 solo hay que contar cuantas partes de periodo existen diferentes con RE y ese es el numero de cuatri o bimestre
        ----proyecto de CURSERA
     IF vnivel in ('MA','MS'  ) then

         begin

          select distinct counT(datos.ptrm)
          INTO vnum_periodo
            from (
            select  count(F.SFRSTCR_PTRM_CODE ) ,F.SFRSTCR_TERM_CODE, F.SFRSTCR_PTRM_CODE ptrm
            from sfrstcr f, ssbsect bb
            where 1=1
            and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
            and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
            and f.SFRSTCR_PIDM = P_PIDM
            and F.SFRSTCR_RSTS_CODE  = 'RE'
            and substr(F.SFRSTCR_TERM_CODE,5,1)  not in (8,9)
            and f.SFRSTCR_STSP_KEY_SEQUENCE = vstudy
            --AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%H%') se comenta esta linea regla de fernando 01.03.2023
            AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%SESO%')
            AND  F.SFRSTCR_PTRM_CODE  NOT IN (select ZSTPARA_PARAM_VALOR
                                                    from ZSTPARA
                                                    where 1=1
                                                    AND ZSTPARA_MAPA_ID = 'PARTES_MAESTRIA'  )
            group by F.SFRSTCR_TERM_CODE, SFRSTCR_PTRM_CODE
            )datos
            where 1=1;


         exception when otherS then
          vnum_periodo := 0;
         end;

     ELSE  --AQUI CUENTA LIC

        begin

          select distinct counT(datos.ptrm)
          INTO vnum_periodo
            from (
            select  count(F.SFRSTCR_PTRM_CODE ) ,F.SFRSTCR_TERM_CODE , SFRSTCR_PTRM_CODE ptrm
            from sfrstcr f, ssbsect bb
            where 1=1
            and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
            and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
            and f.SFRSTCR_PIDM = P_PIDM
            and F.SFRSTCR_RSTS_CODE  = 'RE'
            and substr(F.SFRSTCR_TERM_CODE,5,1)  not in (8,9)
            and f.SFRSTCR_STSP_KEY_SEQUENCE = vstudy
            --AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%H%')   se comenta esta linea regla de fernando 01.03.2023
            AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%SESO%')
            group by F.SFRSTCR_TERM_CODE,SFRSTCR_PTRM_CODE
            )datos
            where 1=1;


         exception when otherS then
          vnum_periodo := 0;
         end;



       END IF;

--
--       begin
--          select REGEXP_SUBSTR(vperiodo,'[0-9]+')
--            INTO vnum_periodo
--              from dual;
--
--       exception when others then
--        vnum_periodo := 0;
--       end;

        BEGIN

            select ZSTPARA_PARAM_DESC VMIN, ZSTPARA_PARAM_VALOR VMAX
                  INTO VMIN, VMAX
                from ZSTPARA
                  where 1=1
                    AND ZSTPARA_MAPA_ID = 'BIMETRES_1SS'
                    AND ZSTPARA_PARAM_ID   = vnivel;


        EXCEPTION WHEN OTHERS THEN
        VMIN := 0;
        VMAX := 0;

        END;
      ----dbms_output.put_line('salida del curso '|| vperiodo|| '  numero '||vnum_periodo|| '  SERVICIO1 ' || vserv||'  SERVICIO2 ' || vserv2);

      IF vnivel in ('MA'  ) then
         IF vnum_periodo BETWEEN ( VMIN ) AND ( VMAX)  then
             vserv3 := 'XX';
            ----dbms_output.put_line('si PRESENTA A1 '|| vserv3);
         ELSE
              vserv3 := 'COMA';
             ----dbms_output.put_line('NO  PRESENTA A2 '|| vserv3);
         END IF;
      END IF;

      IF vnivel in ('MS'  ) then
         IF vnum_periodo BETWEEN ( VMIN ) AND ( VMAX)  then
             vserv3 := 'XX';
            ----dbms_output.put_line('si PRESENTA A1 '|| vserv3);
         ELSE
              vserv3 := 'COMM';
             ----dbms_output.put_line('NO  PRESENTA A2 '|| vserv3);
         END IF;
      END IF;


     IF  vnivel in ('LI' ) THEN
         IF vnum_periodo BETWEEN ( VMIN ) AND (VMAX)  then
                vserv3 := 'XX';
               -- --dbms_output.put_line('si PRESENTA A3 '|| vserv3);
          ELSE

              vserv3 := 'COLI';
              ----dbms_output.put_line('NO  PRESENTA A4 '|| vserv3);

         end if;

     END IF;
       --------HASTA AQUI TERMINA COURSERA----



-- aqui comienza nueva version con ajuste para el calculo de los acce que se muetren o no segun el bimestre que esten
--    cambio x fer incidencia 17.05.2023   glovicx
  OPEN c_out_tienda
         FOR   SELECT
                        b.svrrsso_srvc_code VL_CODE,
                        c.svvsrvc_desc VL_SERVICIO,
                        b.svrrsso_serv_amount VL_COSTO
                        FROM
                        svrrsrv A,
                        svrrsso b,
                        svvsrvc c,
                        tztprog d
                        WHERE 1=1
                        And d.pidm = P_PIDM
                        and d.sp in (select max (d1.sp)
                                            from tztprog d1
                                            Where d1.pidm = d.pidm
                                            And d1.programa = d.programa)
                        And a.SVRRSRV_CAMP_CODE = d.campus
                        And a.SVRRSRV_LEVL_CODE  = d.nivel
                        and (A.SVRRSRV_PROGRAM   = D.PROGRAMA
                         OR A.SVRRSRV_PROGRAM   is null )
                        And a.SVRRSRV_STST_CODE = d.estatus
                        AND a.svrrsrv_srvc_code = b.svrrsso_srvc_code
                        AND a.svrrsrv_seq_no = b.svrrsso_rsrv_seq_no
                        AND c.svvsrvc_code = b.svrrsso_srvc_code
                        AND a.svrrsrv_inactive_ind = 'Y'
                        AND a.svrrsrv_web_ind = 'Y'
                        and  SUBSTR(b.SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(P_PIDM),1,2)
                        And d.SGBSTDN_STYP_CODE = nvl (a.SVRRSRV_STYP_CODE, SGBSTDN_STYP_CODE)
                        and a.svrrsrv_srvc_code in  (SELECT zstpara_param_id
                                                                     FROM  zstpara
                                                                     WHERE 1=1
                                                                     AND zstpara_mapa_id ='CERTIFICA_1SS'
                                                                     and ZSTPARA_PARAM_ID not in ( vserv,vserv2,vserv3,vserv4  ) )
                        and a.svrrsrv_srvc_code not in
                         ( select  g.SZT_CODE_SERV vl2_code --, G.SZT_DESCRIPCION, 0
                                                                from saturn.SZtGECE g
                                                                where 1=1
                                                                and g.SZT_NIVEL = vnivel
                                                                and g.SZT_CODE_SERV != 'COFU' ---por regla cofu no es una certificación pero fernando la configuro por  que se comporta como tal 21.02.2023
                                                                and g.SZT_TIPO_ALIANZA not in ('Plataformas')
                                                                and vnum_periodo  NOT between to_number(substr(g.SZT_BIM_COMPRA,1,1)) and to_number(substr(g.SZT_BIM_COMPRA,3,3))
                                                                 )
                     ORDER BY 1   ;



       RETURN (c_out_tienda);
 Exception
            When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.cur_servicios: ' || sqlerrm;

        --   return vl_error;

 END f_tienda_solic;

FUNCTION F_TIENDA_ACC (P_PIDM IN NUMBER) RETURN PKG_SERV_SIU.cursor_out_tienda
IS

c_out_tienda PKG_SERV_SIU.cursor_out_tienda;
-- c_out_tienda BANINST1.PKG_SERV_SIU.servicios_type;
vl_error     varchar2(500);

vprograma varchar2(15):= NULL;
vnivel    varchar2(5):= null;
vcampus   varchar2(5):= null;
vcampus2   varchar2(5):= null;
vperiodo  varchar2(30);
vnum_periodo  number:=0;
vstudy        number:=0;
VMIN          NUMBER:= 0;
VMAX          NUMBER:= 0;
vsaldo       number:=0;
vadeudo     number:=0;
VAVANCE    number:=0;
vserv1        varchar2(8):='XX';
vserv2        varchar2(8):='XX';
vserv3        varchar2(8):='XX';
vrango1     number:= 0;
vrango2     number:= 0;
vcodigo     varchar2(6);

 
 vcursor       SYS_REFCURSOR;
 vvalor1       varchar2(200):='XX';
 vserv4        varchar2(8):='XX';
vP_ADID_ID    varchar2(8):='AUSS';
 vserv5      varchar2(8):='XX';
 vl_existe    number:=0;
 vconta_doc   number:=0;
 VSSO        varchar2(1):='Y';
 vserv6      varchar2(8):='XX';
VDOCTOSS     varchar2(8):='50';
 vserv7      varchar2(8):='DTMA';
 VAVDTMA     varchar2(1):='Y';
 vestatus     varchar2(2);
 vingreso     varchar2(4);
 

 BEGIN

 --ESTA TIENDITA ES PARA MOSTRAR LOS ACCESORIOS NO CURSOS++ NUEVA GLOVICX 20/10/2021
 --  se arregla este query ya no usa el appi nativo. glovicx 3006022

--- nueva validación para diplomas QR de EC, se le agrega la validacion del adeudo glovicx..24.01.2023
-- ajuste de AVCU para tomarlo de THITA,se cambio 08.04.2025

       begin
            vsaldo:= NVL(BANINST1.PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia_Titulo (P_PIDM),0);

        exception when others then
          vsaldo := 0;
        end;
    ----  aqui comienza las colegiaturas finales COLF y COFU  glovicx 30.01.2023---
        begin
                select distinct t.programa, T.NIVEL, T.CAMPUS,T.ESTATUS,  t.TIPO_INGRESO
                   into vprograma, VNIVEL, vcampus, vestatus, vingreso
                    from tztprog t
                        where 1=1
                          and T.ESTATUS not in ('CV','CP' )
                          and  t.pidm = P_PIDM
                            and t.sp = ( select max (t2.sp)  from tztprog t2
                                                     where 1=1
                                                       and T2.ESTATUS not in ('CV','CP' )
                                                        and   t.pidm = t2.pidm );

        exception when others then
          vprograma  := null;
          vcampus  := null;
          vestatus := null;

        end;

       -- --dbms_output.PUT_LINE('SALIDA programa :: '|| VPROGRAMA);

         -- --dbms_output.put_line('saldo de adeudo :  '|| vsaldo  );
        ---busco la cantidad de adeudo maximo permitido para DIPLOMAS QR glovicx 24.01.2023

         begin
          null;

         select NVL(sum(SZT_ADEUDO),0)
           INTO vadeudo
         from sztdoca
         where 1=1
         and SZT_CODE_ACC = 'DIPD'
         and SZT_NIVEL   =  VNIVEL;

         exception when others then
          vadeudo := 0;
         end;

   ----dbms_output.put_line('salida adeuDO EN DOCA :  '||vsaldo ||'->>>'|| vadeudo  );
        IF vsaldo > vadeudo then  --- si saldo es MAYOR AL  adeudo(DOCA) NO Aparece
           vserv1 := 'DIPD';
        end if;


                ---buscamos el avance para la regla
                --- aqui se cambia el avance x Thita  glovicx 07.04.2025
         BEGIN
          
             VAVANCE :=0;
             
                   SELECT ROUND(nvl(SZTHITA_AVANCE,0))
                      INTO VAVANCE
                        FROM SZTHITA ZT
                        WHERE ZT.SZTHITA_PIDM   = P_PIDM
                        AND    ZT.SZTHITA_LEVL  = VNIVEL
                        AND   ZT.SZTHITA_PROG   = VPROGRAMA  ;
                        
                        ----dbms_output.PUT_LINE('SALIDA AVANCE HITA  '|| VDESC2);
          EXCEPTION WHEN OTHERS THEN
              
                        BEGIN
                           SELECT ROUND(BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 ( P_PIDM, vPROGRAMA ))
                                  INTO VAVANCE
                             FROM DUAL;

                          --   --dbms_output.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
                          EXCEPTION WHEN OTHERS THEN
                           VAVANCE :=0;
                          END;
          END;
           
        /* COFU DEL 0 AL 70%
           COLF  DEL 71 AL 100%
        */

       if VAVANCE > 100 then
           VAVANCE := 100;
       end if;
           ----- recuperamos los rangos del para  glovicx 21.20.2023
           begin
                   select to_number(substr(ZSTPARA_PARAM_VALOR,1, instr(ZSTPARA_PARAM_VALOR,',',1 )-1  )) rango1,
                            to_number(substr(ZSTPARA_PARAM_VALOR,instr(ZSTPARA_PARAM_VALOR,',',1 )+1,3  )) rango2,
                             ZSTPARA_PARAM_ID  codigo,
                              substr(ZSTPARA_PARAM_DESC,1,3)   campus2
                                into vrango1,vrango2,vcodigo,vcampus2
                            from ZSTPARA
                            where 1=1
                            and ZSTPARA_MAPA_ID =  'PORCENTAJE_COFU'
                            and  substr(ZSTPARA_PARAM_DESC,5,2) = VNIVEL
                            and  substr(ZSTPARA_PARAM_DESC,1,3) = vcampus
                            and  to_number(VAVANCE)  between  to_number(substr(ZSTPARA_PARAM_VALOR,1, instr(ZSTPARA_PARAM_VALOR,',',1 )-1  ))
                            and to_number(substr(ZSTPARA_PARAM_VALOR,instr(ZSTPARA_PARAM_VALOR,',',1 )+1,3  ));



            exception when others then
           vrango1 := null;
           vrango2:= null;
           vcodigo := null;
           vcampus2:= null;


           end;

                ---- para COFU si se valida el adeudo para colf NO regla ref 07.02.2023 glovicx
                -- COFU solo es para campus UTL del 0 al 79
               -- COLF UTL > del 80% al 100%

        IF VAVANCE < 0 then  --- si no cumple con la configuracion minima, entonces no presenta ninguno de los dos   regla de fer 07.02.2023
         
         vserv3 := 'COFU';
         vserv2 := 'COLF' ;
            ----dbms_output.put_line('no presenta nada  :  '||vserv3 ||'->>>'|| vserv2  );
            -- COFU  solo es para UTL no va para otros campus

        ELSIF vcodigo = 'COFU'   then  -- calcula primera regla y es solo cofu

             IF   VAVANCE >= vrango1 and  VAVANCE <= vrango2 and vcampus = vcampus2   then   --- nuevo ajuste de regla x fernando 21.04.2023
                ---validamos el adeudo--   esta seccion es solo para COFU y solo es para UTL
                --dbms_output.put_line('estoy en la seccion de COFU y UTL' ||VAVANCE||'-rango1-'|| vrango1||'-rango2-'|| vrango2||'-campus1-'|| vcampus||'-campus2-'|| vcampus2 );

                  begin
                                 select NVL(sum(SZT_ADEUDO),0)
                                   INTO vadeudo
                                 from sztdoca
                                 where 1=1
                                 and SZT_CODE_ACC = 'COFU'
                                 and SZT_NIVEL   = VNIVEL;
                         exception when others then
                          vadeudo := 0;
                         end;


                         --  --dbms_output.put_line('salida avance 14-70 :  '||VAVANCE ||'->>>'||vsaldo||'--->'|| vadeudo  );
                        IF vsaldo > vadeudo then  --- si saldo es MAYOR AL  adeudo(DOCA) NO Aparece
                           vserv3 := 'COFU'; --si tiene adeudo bloque COFU aun que si tenga el %
                           else
                            vserv2 := 'COLF';  -- con esta cccion bloquea COLF por que si esta en el % de COFU
                        end if;

              end if;


         ELSE  ----aqui es COLF  UTL y UTS son de 80 al 100%
                      ---  COLF todos los demas campus son del 0 al 100%

        NULL;

             --- se hace un nuevo ajuste deacuerdo al mail de BETzy 21.04.2023 se hace separacion x nivel, campus para COLF
                         ----- BUSCAMOS EN EL PARAMETRIZADOR DE % DE AVANCE
                    IF   VAVANCE >= vrango1 and  VAVANCE <= vrango2 and vcampus = vcampus2   then   --- nuevo ajuste de regla x fernando 21.04.2023

                    vserv2 := 'XX';  --- esto quiere decir que si cumple con las reglas y se de debe de presentar
                    vserv3 := 'COFU'; --- con esto bloquemos COFU
                    else
                    vserv2 := 'COLF'; --- aqui quiere decir que lo bloquea x que no cumple
                    end if;
          --dbms_output.put_line('estoy en la seccion de COLF y UTL' ||VAVANCE||'-rango1-'|| vrango1||'-rango2-'|| vrango2||'-campus1-'|| vcampus||'-campus2-'|| vcampus2 );
         END IF;

        ---- aqui va la nueva validacion para los accesorios de DPLO glovicx 12-04-2024
     ---- para esconder el accesorio DPLO si así fuera el caso x no cumplir con las reglas
    
    begin
            vcursor :=  BANINST1.PKG_SERV_SIU.F_CURSO_DPLO  (P_PIDM , vprograma , 'AUTO_SIU'  ); 
       
      LOOP
             FETCH vcursor
          
            INTO vserv4,vvalor1;     ---F_CURSO_DPLO
          
            EXIT WHEN vcursor%NOTFOUND;
          
           
      end loop;
   
       --  dbms_output.put_line(' AL -FINALIZAR cursor- DPLO:. ' ||vserv4 );
            
        
         
         
             IF vcursor%ISOPEN THEN
               CLOSE vcursor;
               END IF;   
        
      exception when others then
      null;
       --dbms_output.put_line(' error en fase de dplo cursor- ' ||sqlerrm );
      end;
      
      
      
    
    -------validacion  para los accesorios de servicio social glovicx 22.11.2024
    ----- validamos que exista la etiqueta AUSS si existe entonces se presentan los 2 acc de SS
    
          Begin ---- si lo encuantra entonces si presenta el accesorio: Carta de presentación para servicio social (CPRE).
            Select count(1)
                Into vl_existe
              from GENERAL.GORADID
           Where GORADID_PIDM = P_PIDM
            And GORADID_ADID_CODE  = vP_ADID_ID;
           Exception  When Others then
               vl_existe :=0;
          End;
     
    
    IF vl_existe >= 1 then   ---- COMO ES LA SEGUNDA PARTE DEL FLUJO los documentos ya fueron validados en el proceso general de betzy
        
      vserv5  := 'XX';
      
      else   -- NO cumple y se oculta en la tienda
      
      vserv5  := 'CPRE'; 
      
      end if;
      
       BEGIN
            select distinct 'Y'
              INTO VSSO
                from SHRNCRS R
                where 1=1
                AND R.SHRNCRS_PIDM = P_PIDM
                AND R.SHRNCRS_NCST_CODE = 'AP'
                AND R.SHRNCRS_NCRQ_CODE = 'SS';
       exception when others then
       VSSO := 'N';
       
         --dbms_output.put_line('ERROR EN SERVICIO SOCIAL'|| VSSO );
       END;
      
       IF VSSO = 'Y' THEN
       
        vserv6  := 'XX';
      
        else   -- NO cumple y se oculta en la tienda
      
       vserv6  := 'CLRE'; 
       
       END IF;
      
    ---aqui comienza DTMA producion cientifica  glovicx 20.02.2025
     
    
     begin  ---  aqui NO cumple con el avance entonces NO se ve el accorio DTMA
        -- dbms_output.put_line('dtma'|| VAVANCE );
         
         select 'XX'
           INTO   vserv7  
             FROM  zstpara
              WHERE 1=1
                AND zstpara_mapa_id ='DTMA_AV'
                and VAVANCE >= TO_NUMBER(ZSTPARA_PARAM_VALOR) ;
      
     exception when others then
      vserv7 := 'DTMA';
     -- dbms_output.put_line('error en dtma'|| VAVANCE );
      
      end;
    
     
        --dbms_output.put_line('si/no  ENTRA A LOS PARAMETROS NO PRESENTA EL SERVICIO '|| VNIVEL||'-'|| vserv1||'--'|| vserv2||'-'|| vserv3);
       OPEN c_out_tienda
         FOR   SELECT DISTINCT
                    b.svrrsso_srvc_code VL_CODE,
                    c.svvsrvc_desc VL_SERVICIO,
                    b.svrrsso_serv_amount VL_COSTO
                FROM
                    svrrsrv A,
                    svrrsso b,
                    svvsrvc c,
                    tztprog d
                    WHERE 1=1
                    And d.pidm = P_PIDM
                    and d.sp in (select max (d1.sp)
                                        from tztprog d1
                                        Where d1.pidm = d.pidm
                                        And d1.programa = d.programa)
                    And a.SVRRSRV_CAMP_CODE = d.campus
                    And a.SVRRSRV_LEVL_CODE  = d.nivel
                    And a.SVRRSRV_STST_CODE = d.estatus
                    AND a.svrrsrv_srvc_code = b.svrrsso_srvc_code
                    AND a.svrrsrv_seq_no = b.svrrsso_rsrv_seq_no
                    AND c.svvsrvc_code = b.svrrsso_srvc_code
                    AND a.svrrsrv_inactive_ind = 'Y'
                    AND a.svrrsrv_web_ind = 'Y'
                    And d.SGBSTDN_STYP_CODE = nvl (a.SVRRSRV_STYP_CODE, SGBSTDN_STYP_CODE)
                    --AND a.svrrsrv_seq_no = BANINST1.bvgkptcl.F_apply_rule_protocol (162126, A.SVRRSRV_SRVC_CODE)
                    and a.svrrsrv_srvc_code in (SELECT zstpara_param_id
                                                                FROM zstpara
                                                                WHERE 1=1
                                                                AND zstpara_mapa_id ='AUTOSERVICIOSIU'
                                                                and ZSTPARA_PARAM_ID not in ( vserv1,vserv2,vserv3,vserv4,vserv5,vserv6,vserv7 )
                                                                )
                    ORDER BY c.svvsrvc_desc;


       RETURN (c_out_tienda);
       
 Exception
            When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.cur_servicios: ' || sqlerrm;
           --  dbms_output.put_line('error en general f_tienda_acc:   '|| vl_error);
           return c_out_tienda;

 END F_TIENDA_ACC;

FUNCTION F_MENU_SERV (ppidm in number) Return PKG_SERV_SIU.servicios_type
IS
 cur_servicios BANINST1.PKG_SERV_SIU.servicios_type;

vserv    VARCHAR2(5);

---

vprograma varchar2(15):= NULL;
vnivel    varchar2(5):= null;
vcampus   varchar2(5):= null;
vcampus2   varchar2(5):= null;
vperiodo  varchar2(30);
vnum_periodo  number:=0;
vstudy        number:=0;
VMIN          NUMBER:= 0;
VMAX          NUMBER:= 0;
vsaldo       number:=0;
vadeudo     number:=0;
VAVANCE    number:=0;
vserv1        varchar2(8):='XX';
vserv2        varchar2(8):='XX';
vserv3        varchar2(8):='XX';
vrango1     number:= 0;
vrango2     number:= 0;
vcodigo     varchar2(6);

 
 vcursor       SYS_REFCURSOR;
 vvalor1       varchar2(200):='XX';
 vserv4        varchar2(8):='XX';
vP_ADID_ID    varchar2(8):='AUSS';
 vserv5      varchar2(8):='XX';
 vl_existe    number:=0;
 vconta_doc   number:=0;
 VSSO        varchar2(1):='Y';
 vserv6      varchar2(8):='XX';
VDOCTOSS     varchar2(8):='50';
 vserv7      varchar2(8):='DTMA';
 VAVDTMA     varchar2(1):='Y';
 vestatus     varchar2(2);
 vingreso     varchar2(4);
 


 begin
  ----vamos a validar si el alumno ya tiene el servicio de sesiones ejecutivas entonces ya no se lo presente en el tapiz de compras --glovicx 15/01/2021
  -- se hace un ajuste para que no se brinquen el candado de SS  glovicx 04.03. 2025

   begin
           SELECT distinct decode(substr(SZTALOL_PROGRAMA,4,2),'LI','SEJL','MA','SEJM') SERVICIO
               into vserv
             FROM sztalol
                where 1=1
                and SZTALOL_PIDM = PPIDM
                  and SZTALOL_ESTATUS = 'A';

   exception when others then
        vserv := 'XX';
    end;

          -----------------------
     
--- nueva validación para diplomas QR de EC, se le agrega la validacion del adeudo glovicx..24.01.2023
-- ajuste de AVCU para tomarlo de THITA,se cambio 08.04.2025
-- se ajusta se quita procso de validacion de dplo  glovicx 29.04.2025

       begin
            vsaldo:= NVL(BANINST1.PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia_Titulo (PPIDM),0);

        exception when others then
          vsaldo := 0;
        end;
    ----  aqui comienza las colegiaturas finales COLF y COFU  glovicx 30.01.2023---
        begin
                select distinct t.programa, T.NIVEL, T.CAMPUS,T.ESTATUS,  t.TIPO_INGRESO
                   into vprograma, VNIVEL, vcampus, vestatus, vingreso
                    from tztprog t
                        where 1=1
                          and T.ESTATUS not in ('CV','CP' )
                          and  t.pidm = PPIDM
                            and t.sp = ( select max (t2.sp)  from tztprog t2
                                                     where 1=1
                                                       and T2.ESTATUS not in ('CV','CP' )
                                                        and   t.pidm = t2.pidm );

        exception when others then
          vprograma  := null;
          vcampus  := null;
          vestatus := null;

        end;

       -- --dbms_output.PUT_LINE('SALIDA programa :: '|| VPROGRAMA);

         -- --dbms_output.put_line('saldo de adeudo :  '|| vsaldo  );
        ---busco la cantidad de adeudo maximo permitido para DIPLOMAS QR glovicx 24.01.2023

         begin
          null;

         select NVL(sum(SZT_ADEUDO),0)
           INTO vadeudo
         from sztdoca
         where 1=1
         and SZT_CODE_ACC = 'DIPD'
         and SZT_NIVEL   =  VNIVEL;

         exception when others then
          vadeudo := 0;
         end;

   ----dbms_output.put_line('salida adeuDO EN DOCA :  '||vsaldo ||'->>>'|| vadeudo  );
        IF vsaldo > vadeudo then  --- si saldo es MAYOR AL  adeudo(DOCA) NO Aparece
           vserv1 := 'DIPD';
        end if;


                ---buscamos el avance para la regla
                --- aqui se cambia el avance x Thita  glovicx 07.04.2025
         BEGIN
          
             VAVANCE :=0;
             
                   SELECT ROUND(nvl(SZTHITA_AVANCE,0))
                      INTO VAVANCE
                        FROM SZTHITA ZT
                        WHERE ZT.SZTHITA_PIDM   = PPIDM
                        AND    ZT.SZTHITA_LEVL  = VNIVEL
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
           
        /* COFU DEL 0 AL 70%
           COLF  DEL 71 AL 100%
        */

       if VAVANCE > 100 then
           VAVANCE := 100;
       end if;
           ----- recuperamos los rangos del para  glovicx 21.20.2023
           begin
                   select to_number(substr(ZSTPARA_PARAM_VALOR,1, instr(ZSTPARA_PARAM_VALOR,',',1 )-1  )) rango1,
                            to_number(substr(ZSTPARA_PARAM_VALOR,instr(ZSTPARA_PARAM_VALOR,',',1 )+1,3  )) rango2,
                             ZSTPARA_PARAM_ID  codigo,
                              substr(ZSTPARA_PARAM_DESC,1,3)   campus2
                                into vrango1,vrango2,vcodigo,vcampus2
                            from ZSTPARA
                            where 1=1
                            and ZSTPARA_MAPA_ID =  'PORCENTAJE_COFU'
                            and  substr(ZSTPARA_PARAM_DESC,5,2) = VNIVEL
                            and  substr(ZSTPARA_PARAM_DESC,1,3) = vcampus
                            and  to_number(VAVANCE)  between  to_number(substr(ZSTPARA_PARAM_VALOR,1, instr(ZSTPARA_PARAM_VALOR,',',1 )-1  ))
                            and to_number(substr(ZSTPARA_PARAM_VALOR,instr(ZSTPARA_PARAM_VALOR,',',1 )+1,3  ));



            exception when others then
           vrango1 := null;
           vrango2:= null;
           vcodigo := null;
           vcampus2:= null;


           end;

                ---- para COFU si se valida el adeudo para colf NO regla ref 07.02.2023 glovicx
                -- COFU solo es para campus UTL del 0 al 79
               -- COLF UTL > del 80% al 100%

        IF VAVANCE < 0 then  --- si no cumple con la configuracion minima, entonces no presenta ninguno de los dos   regla de fer 07.02.2023
         
         vserv3 := 'COFU';
         vserv2 := 'COLF' ;
            ----dbms_output.put_line('no presenta nada  :  '||vserv3 ||'->>>'|| vserv2  );
            -- COFU  solo es para UTL no va para otros campus

        ELSIF vcodigo = 'COFU'   then  -- calcula primera regla y es solo cofu

             IF   VAVANCE >= vrango1 and  VAVANCE <= vrango2 and vcampus = vcampus2   then   --- nuevo ajuste de regla x fernando 21.04.2023
                ---validamos el adeudo--   esta seccion es solo para COFU y solo es para UTL
                --dbms_output.put_line('estoy en la seccion de COFU y UTL' ||VAVANCE||'-rango1-'|| vrango1||'-rango2-'|| vrango2||'-campus1-'|| vcampus||'-campus2-'|| vcampus2 );

                  begin
                                 select NVL(sum(SZT_ADEUDO),0)
                                   INTO vadeudo
                                 from sztdoca
                                 where 1=1
                                 and SZT_CODE_ACC = 'COFU'
                                 and SZT_NIVEL   = VNIVEL;
                         exception when others then
                          vadeudo := 0;
                         end;


                         --  --dbms_output.put_line('salida avance 14-70 :  '||VAVANCE ||'->>>'||vsaldo||'--->'|| vadeudo  );
                        IF vsaldo > vadeudo then  --- si saldo es MAYOR AL  adeudo(DOCA) NO Aparece
                           vserv3 := 'COFU'; --si tiene adeudo bloque COFU aun que si tenga el %
                           else
                            vserv2 := 'COLF';  -- con esta cccion bloquea COLF por que si esta en el % de COFU
                        end if;

              end if;


         ELSE  ----aqui es COLF  UTL y UTS son de 80 al 100%
                      ---  COLF todos los demas campus son del 0 al 100%

        NULL;

             --- se hace un nuevo ajuste deacuerdo al mail de BETzy 21.04.2023 se hace separacion x nivel, campus para COLF
                         ----- BUSCAMOS EN EL PARAMETRIZADOR DE % DE AVANCE
                    IF   VAVANCE >= vrango1 and  VAVANCE <= vrango2 and vcampus = vcampus2   then   --- nuevo ajuste de regla x fernando 21.04.2023

                    vserv2 := 'XX';  --- esto quiere decir que si cumple con las reglas y se de debe de presentar
                    vserv3 := 'COFU'; --- con esto bloquemos COFU
                    else
                    vserv2 := 'COLF'; --- aqui quiere decir que lo bloquea x que no cumple
                    end if;
          --dbms_output.put_line('estoy en la seccion de COLF y UTL' ||VAVANCE||'-rango1-'|| vrango1||'-rango2-'|| vrango2||'-campus1-'|| vcampus||'-campus2-'|| vcampus2 );
         END IF;

        ---- aqui va la nueva validacion para los accesorios de DPLO glovicx 12-04-2024
     ---- para esconder el accesorio DPLO si así fuera el caso x no cumplir con las reglas
     --  se quito esta validación por que chocaba cuando seleccionaba las preguntas glovicx 29.04.2025
    /* 
     begin
            vcursor :=  BANINST1.PKG_SERV_SIU.F_CURSO_DPLO  (P_PIDM , vprograma , 'AUTO_SIU'  ); 
       
      LOOP
             FETCH vcursor
          
            INTO vserv4,vvalor1;     ---F_CURSO_DPLO
          
            EXIT WHEN vcursor%NOTFOUND;
          
           
      end loop;
   
         --dbms_output.put_line(' AL -FINALIZAR cursor- ' ||vserv4 );
   
             IF vcursor%ISOPEN THEN
               CLOSE vcursor;
               END IF;   
        
      exception when others then
      null;
       --dbms_output.put_line(' error en fase de dplo cursor- ' ||sqlerrm );
      end;
      
     */ 
    -------validacion  para los accesorios de servicio social glovicx 22.11.2024
    ----- validamos que exista la etiqueta AUSS si existe entonces se presentan los 2 acc de SS
    
          Begin ---- si lo encuantra entonces si presenta el accesorio: Carta de presentación para servicio social (CPRE).
            Select count(1)
                Into vl_existe
              from GENERAL.GORADID
           Where GORADID_PIDM = PPIDM
            And GORADID_ADID_CODE  = vP_ADID_ID;
           Exception  When Others then
               vl_existe :=0;
          End;
     
    
    IF vl_existe >= 1 then   ---- COMO ES LA SEGUNDA PARTE DEL FLUJO los documentos ya fueron validados en el proceso general de betzy
        
      vserv5  := 'XX';
      
      else   -- NO cumple y se oculta en la tienda
      
      vserv5  := 'CPRE'; 
      
     end if;
      
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
       
         --dbms_output.put_line('ERROR EN SERVICIO SOCIAL'|| VSSO );
       END;
      
      
       IF VSSO = 'Y' THEN
       
        vserv6  := 'XX';
        
      
        else   -- NO cumple y se oculta en la tienda
      
        vserv6  := 'CLRE'; 
       
       
       END IF;
      
      

     
    ---aqui comienza DTMA producion cientifica  glovicx 20.02.2025
     
    
     begin  ---  aqui NO cumple con el avance entonces NO se ve el accorio DTMA
        -- dbms_output.put_line('dtma'|| VAVANCE );
         
         select 'XX'
           INTO   vserv7  
             FROM  zstpara
              WHERE 1=1
                AND zstpara_mapa_id ='DTMA_AV'
                and VAVANCE >= TO_NUMBER(ZSTPARA_PARAM_VALOR) ;
      
     exception when others then
      vserv7 := 'DTMA';
      --dbms_output.put_line('error en dtma'|| VAVANCE );
      
      end;
    
     
     
     
     

    open cur_servicios for select distinct A.SVRRSRV_SRVC_CODE AS CODIGO,
                    sv_svvsrvc.f_get_description (A.SVRRSRV_SRVC_CODE) srvc_code_desc
                  , a.SVRRSRV_SEQ_NO
                FROM
                    svrrsrv A,
                    svrrsso b,
                    svvsrvc c,
                    tztprog d
                    WHERE 1=1
                    And d.pidm = ppidm
                    and d.sp in (select max (d1.sp)
                                        from tztprog d1
                                        Where d1.pidm = d.pidm
                                        And d1.programa = d.programa)
                    And a.SVRRSRV_CAMP_CODE = d.campus
                    And a.SVRRSRV_LEVL_CODE  = d.nivel
                    And a.SVRRSRV_STST_CODE = d.estatus
                    AND a.svrrsrv_srvc_code = b.svrrsso_srvc_code
                    AND a.svrrsrv_seq_no = b.svrrsso_rsrv_seq_no
                    AND c.svvsrvc_code = b.svrrsso_srvc_code
                    AND a.svrrsrv_inactive_ind = 'Y'
                    AND a.svrrsrv_web_ind = 'Y'
                    And d.SGBSTDN_STYP_CODE = nvl (a.SVRRSRV_STYP_CODE, SGBSTDN_STYP_CODE)
                   and A.SVRRSRV_SRVC_CODE in  (  SELECT ZSTPARA_PARAM_ID  
                                                    FROM  SATURN.ZSTPARA
                                                  WHERE 1=1
                                                  and ZSTPARA_MAPA_ID ='AUTOSERVICIOSIU'
                                                  and ZSTPARA_PARAM_ID not in ( vserv1,vserv2,vserv3,vserv4,vserv5,vserv6,vserv7  ) )
                  ORDER BY 1 ASC;

    -- dbms_output.put_line('antes de cursor  '|| ppidm );


           return cur_servicios;


 Exception When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.cur_servicios: ' || sqlerrm;
           return cur_servicios;
 end F_MENU_SERV;




FUNCTION F_CAMPOS_SERV (pCODE in VARCHAR2 ) Return PKG_SERV_SIU.campos_type
IS
 CUR_CAMPOS BANINST1.PKG_SERV_SIU.campos_type;


 begin

        open CUR_CAMPOS for  select SVRSRAD_SRVC_CODE,
                                SVRSRAD_ADDL_DATA_SEQ,
                                SVRSRAD_ADDL_DATA_TITLE,
                                SVRSRAD_VIEW_SOURCE||'2',
                                SVRSRAD_REQUIRED_IND
                                from SVRSRAD
                                where UPPER(SVRSRAD_SRVC_CODE) = UPPER(pCODE)
                                AND SVRSRAD_WEB_IND = 'Y'
                                 ORDER BY 2 ASC;

       return CUR_CAMPOS;
    Exception
            When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
           return CUR_CAMPOS;
    end F_CAMPOS_SERV;

FUNCTION F_COSTO_SERV (Ppidm in NUMBER, PCODE  IN VARCHAR2 , PNO_SERVI number, pprograma varchar2  ) Return NUMBER
IS

metodo_tax  VARCHAR2(2);
metodo      NUMBER:=0;
metodo2     NUMBER:=0;
VCOSTO      NUMBER:=0;
porcentaje  number:=0;
monto       number:=0;
descuento   number:=0;
codigo      VARCHAR2(4);
v_acc_costo_cero   VARCHAR2(6);
Vcursera     varchar2(1):='N';
VMESES       number:=0;
VCODE_DTLX   VARCHAR2(10);
vseqno2      number;
vsaldo       number:=0;
vetiqueta    varchar2(5);
vl_existe   number:=0;
vdias      number:=0;
vegresado    varchar2(1):='N';
v_upsell    number:=0;
Vexist      number:=0;


 begin
  --     se genera nueva version de calculo de costo por servicio sin tomar en cuenta los metodos---glovicx 13082019--

          ---se realizo este cambio para que nivelacion mostrara el precio real segun nivel  GLOVICX 2/08/2017**
      ------se valida primero que el tipo no se GN = generico ------

     --------para los costos ceros ---


     ---AQUI VAMOS A PONER LA NUEVA REGLA PARA VER SI TIENE COSTO CERO QUE LO HAYA COMPRADO EN PAQUETE  GLOVICX 02/08/2021---
      v_acc_costo_cero := PKG_SERV_SIU.F_accesorio_costo_cero (ppidm , pcode , NULL , pprograma   );

     --se me regresa un Y  es que si existe y se debe de insertar solo el accesorio costo cero y el num transaccciom de tbraccd
    IF substr(v_acc_costo_cero,1,1) = 'Y' and substr(v_acc_costo_cero,3,3) >= 1  then
     --if v_acc_costo_cero = 'Y|1' then

      VCOSTO := 0;
      --tran_number := substr(v_acc_costo_cero,3,3);
      --vvalida    := substr(v_acc_costo_cero,1,1);


    -- insert into twpasow( valor1, valor2, valor3, valor4, VALOR5)
        --values ('func_COSTO_SERVICIO_despues ',ppidm,pcode, v_acc_costo_cero,VCOSTO  );

   else
            ------procedimiento para cursera--- glovicx 30/09/021
            --aqui hace la validacion de cursera si tiene un MES si entra el pago si a 12 no debe de entrar glovicx 29/09/2021

         begin
            select 'Y'
               INTO  Vcursera
             From ZSTPARA
               where 1=1
                AND ZSTPARA_MAPA_ID = 'CODI_NIVE_UNICA'
                and ZSTPARA_PARAM_DESC like('COURSERA%')
                and ZSTPARA_PARAM_ID = PCODE;


         exception when others then
         Vcursera := 'N';
         end;

     IF Vcursera = 'Y'  then
     -------CURSERA BUSCA LOS MESES SI ES UNO PASA Y SIN ES 12 NO PASA GLOVIC 29/09/2021
             BEGIN
                 select decode(trim(datos.meses),'UN',1,trim(datos.meses)) mesess, CODE_DTL,seqno2
                    into VMESES,VCODE_DTLX, vseqno2
                     from (
                        select DISTINCT SUBSTR(SVRSVAD_ADDL_DATA_DESC,1,INSTR(SVRSVAD_ADDL_DATA_DESC,' ',1)) meses
                        , SVRSVAD_ADDL_DATA_CDE  CODE_DTL,
                        V.SVRSVPR_PROTOCOL_SEQ_NO  seqno2
                        from svrsvpr v,SVRSVAD VA
                        where SVRSVPR_SRVC_CODE = PCODE
                        and SVRSVPR_SRVS_CODE   != 'CA'
                        AND  SVRSVPR_PIDM    = PPIDM
                        and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                        and va.SVRSVAD_ADDL_DATA_SEQ = '5'---CLAVE DE CODIGO DTL
                        ) datos;

            EXCEPTION WHEN OTHERS THEN
            VMESES := 0;

            END;
      end if;

--      insert into twpasow( valor1, valor2, valor3, valor4, VALOR5,valor6)
--        values ('func_COSTO_SERVICIO_curseraAA: ',ppidm,pcode, VCODE_DTLX,VMESES,vseqno2  );

        --HACE LA VALIDACION CURSERA--solo si cumple la función que sea un pago
        IF Vcursera = 'Y' AND VMESES = 1 THEN

           begin
               select  ZSTPARA_PARAM_VALOR costo
                INTO  VCOSTO
                From ZSTPARA
                where 1=1
                AND ZSTPARA_MAPA_ID = 'COSTOS_COURSERA'
                and ZSTPARA_PARAM_DESC = VCODE_DTLX;
            exception when others then
            VCOSTO := 0;
            end;


        ELSE  ----  --PROCEDIMIENTO NORMAL--para los demas accesorios
            ----------------------------nuevo query------------------------------

         SELECT DISTINCT (a.svrrsso_serv_amount)
            INTO VCOSTO
            FROM svrrsso A, tbbdetc B, sorlcur C, svrrsrv D
            WHERE 1=1
            AND a.svrrsso_srvc_code = UPPER(PCODE) --UPPER('NIVE')
            AND a.svrrsso_srvc_code = d.svrrsrv_srvc_code
            AND a.svrrsso_rsrv_seq_no = d.svrrsrv_seq_no
            AND c.sorlcur_camp_code = d.svrrsrv_camp_code
            AND a.svrrsso_detl_code = b.tbbdetc_detail_code
            AND b.tbbdetc_amount = a.svrrsso_serv_amount
           -- AND b.tbbdetc_taxt_code = c.sorlcur_levl_code
            AND b.tbbdetc_detc_active_ind = 'Y'
            AND c.sorlcur_lmod_code = 'LEARNER'
            AND a.svrrsso_rsrv_seq_no = PNO_SERVI
            AND c.sorlcur_pidm = Ppidm
             AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(Ppidm),1,2)
            AND c.sorlcur_seqno = (SELECT MAX (c1.sorlcur_seqno)
                                        FROM sorlcur C1
                                        WHERE 1=1
                                        AND c.sorlcur_pidm = c1.sorlcur_pidm
                                        AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code);



        end if;  --TERMINA NO ES CURSERA



     ---------------------------calcula si hay DESCUENTOS----------------------

    -- --dbms_output.PUT_LINE('COSTO ANTES DEL DESCUENTO'|| VCOSTO   );
      porcentaje := 0;
      monto := 0;

      BEGIN
         SELECT DISTINCT svrrsso_detl_code
           INTO codigo
           FROM svrrsso
          WHERE     svrrsso_srvc_code =  UPPER(PCODE)
                AND svrrsso_rsrv_seq_no = PNO_SERVI;
      EXCEPTION
         WHEN OTHERS
         THEN
            codigo := NULL;
      END;


      BEGIN
         SELECT SWTMDAC_percent_desc, SWTMDAC_amount_desc
           INTO porcentaje, monto
           FROM SWTMDAC
          WHERE     SWTMDAC_pidm = Ppidm
                AND SWTMDAC_detail_code_acc = codigo
                AND SWTMDAC_MASTER_IND = 'Y'
                AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                               SWTMDAC_EFFECTIVE_DATE_INI)
                                        AND TRUNC (
                                               SWTMDAC_EFFECTIVE_DATE_FIN)
                AND SWTMDAC_NUM_REAPPLICATION > SWTMDAC_APPLICATION_INDICATOR
                AND SWTMDAC_FLAG = 'Y';
      EXCEPTION
         WHEN OTHERS
         THEN
            porcentaje := 0;
            monto := 0;
      END;

      descuento := NULL;

      IF porcentaje > 0
      THEN
         descuento := (metodo * (porcentaje / 100));
        -- --dbms_output.put_line('descuento %%%' || descuento);
      END IF;

      IF monto > 0
      THEN
         descuento := monto;
       -- --dbms_output.put_line('descuento_MONTO' || descuento);
      END IF;

--      IF descuento IS NOT NULL
--      THEN
--         v_descuento := '(-)Descuento:';
--      END IF;
     IF VCOSTO = 0 THEN
        SELECT NVL (MAX (svrrsso_serv_amount), 0)
                   INTO VCOSTO
               FROM svrrsso a
                    WHERE     UPPER(svrrsso_srvc_code) = UPPER(PCODE)
                     AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(Ppidm),1,2)
                        AND svrrsso_rsrv_seq_no IN
                           (SELECT MIN (svrrsso_rsrv_seq_no)
                              FROM svrrsso b
                             WHERE a.svrrsso_srvc_code = b.svrrsso_srvc_code
                             AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(Ppidm),1,2));
       END IF;


   end if; --IF principal de costo cero


    --insert into twpasow( valor1, valor2, valor3, valor4, VALOR5)
      --  values ('func_COSTO_SERVICIO_final ',ppidm,pcode, v_acc_costo_cero,VCOSTO  );

    ----return VCOSTO-descuento ;
        return VCOSTO;

   Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
           return VCOSTO;
    end F_COSTO_SERV;




FUNCTION F_COSTO_ENV (pCODE in VARCHAR2, pcampus  varchar2, pnivel varchar2 , pestatus varchar2) Return PKG_SERV_SIU.envios_type
IS
 cur_envio BANINST1.PKG_SERV_SIU.envios_type;


metodo_tax  VARCHAR2(2);
metodo      NUMBER:=0;
metodo2     NUMBER:=0;
VCOSTO      NUMBER:=0;
vdesc_env   VARCHAR2(60);
vcosto_env   number;
vvcode_env   VARCHAR2(5);
vdet_envio   VARCHAR2(50);

 begin

   open cur_envio for   SELECT  distinct W.STVWSSO_CODE, STVWSSO_DESC, STVWSSO_CHRG,  SVRRSSO_SRVC_CODE
                          FROM SVRRSSO SS, STVWSSO W,SVRRSRV
                           WHERE 1=1
                            AND UPPER(SS.SVRRSSO_SRVC_CODE) = UPPER(pCODE)
                            AND svrrsrv_stst_code = pestatus
                            AND svrrsrv_camp_code = pcampus
                            AND svrrsrv_levl_code = pnivel
                            AND SVRRSRV_SEQ_NO = SVRRSSO_RSRV_SEQ_NO
                            AND SVRRSRV_SRVC_CODE = SVRRSRV_SRVC_CODE
                            AND SVRRSSO_SRVC_CODE = SVRRSRV_SRVC_CODE
                            AND SVRRSSO_WSSO_CODE = STVWSSO_CODE;



    return cur_envio;

   Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
          return cur_envio;

    end F_COSTO_ENV;

FUNCTION F_INSRT_SERV (Ppidm in NUMBER, PCODE  IN VARCHAR2 , pPeriodo IN VARCHAR2, Pimporte VARCHAR2, PCAMPUS VARCHAR2,PPCOMENT VARCHAR2
                       ,pcve_envio varchar2 , PPROGRAMA  VARCHAR2 ) Return VARCHAR2
IS
--se agrega el parametro de pprograma para el proyecto de COLF X nivel glovicx 20/05/021
--se agrega el proceso para accesrios costo cero glovicx 30/09/021
--se agrega validación para el proeycto de MES_GRATIS glovicx 19.08.022
-- modif de costo cero UPSELLING cote,caps  glovicx 26.04.2023
-- se agrega validación de nive costo cero glovicx 19.09.2023
-- se anexa el ajuste de para SS_QR CLRE, CPRE  glovicx 03.12.2024


VSALIDA   VARCHAR2(500);
serv        NUMBER:=0;
tran_number   NUMBER:=0;
VIMPORTE     VARCHAR2(10):=0;
rsrv_noseq   NUMBER:=1;
VP_CODEM     NUMBER:=0;
vp_estatus    varchar2(2):= 'AC';
VACC         varchar2(4);
VCAMPEXP     varchar2(4);
vvalida      varchar2(1):= 'N';
VNIVEL        VARCHAR2(3);
v_acc_costo_cero varchar2(10);
VVAL         number:=0;
VSTEP        VARCHAR2(200);  ---- ESTA VARIABLE SE LIBERA EN PROYECTO BENEFICIOS COSTO CERO 26.07.022
vgratis      varchar2(100);
vval_benef   varchar2(1):= 'N';
vaccesorio   varchar2(1):= 'N';
vexisteg     number:=0;
vexistes     varchar2(1):= 'N';
VREJE        VARCHAR2(50);

 begin
--         INSERT INTO TWPASOW(VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,VALOR6,VALOR7,VALOR8,VALOR9)
--          VALUES('WWW_SIU_F_INSRT_SERV:.', Ppidm,  PCODE,pPeriodo,  Pimporte, PCAMPUS,PPCOMENT,pcve_envio,SYSDATE  );
--         COMMIT;
---- esta se quito por que las sesiones ejecutivas ya se compran desde SS1 glovicx 17.04.2023
  /*   IF PCODE IN ('SEJL','SEJM', 'CELI','CEMA','CEMM' )  THEN
       vp_estatus := 'CL';

     ELSE
        vp_estatus := 'AC';

     END IF;
*/

      IF SUBSTR(Pimporte,1,1) = '$' THEN
         VIMPORTE := SUBSTR(Pimporte,2,6);
         ELSE
         NULL;
         VIMPORTE :=Pimporte;
      END IF;


      BEGIN


        select DISTINCT ZSTPARA_PARAM_ID, ZSTPARA_PARAM_VALOR
            INTO  VACC, VCAMPEXP
        from zstpara
        where 1=1
        and ZSTPARA_MAPA_ID   = 'TITULA_DIFERIDA'
        and ZSTPARA_PARAM_VALOR  = PCAMPUS
        AND ZSTPARA_PARAM_ID  = PCODE;


       EXCEPTION WHEN OTHERS THEN
        VACC := NULL;
        VCAMPEXP := NULL;

       END;
   ----dbms_output.put_line('estoy fuera de la validacion  '||PCAMPUS ||'-'|| VCAMPEXP ||'-'|| PCODE ||'-'|| VACC||'-'|| vvalida   );

     IF  PCAMPUS = VCAMPEXP  and PCODE = VACC  then
        vvalida := 'Y';
        ----dbms_output.put_line('estoy en la validacion1  '||  vvalida   );
     end if;



     -- aqui va la validacion para los accesosesrios de costo cero
     --manda llamar la funcion de F_accesorio_costo_cero y si procede poder la variable en vvalida = 'Y'

     v_acc_costo_cero := PKG_SERV_SIU.F_accesorio_costo_cero (ppidm , pcode , pcampus , pprograma   );
      ----dbms_output.put_line('salida de la fucion  '||  v_acc_costo_cero||'-'||  vvalida );

     --se me regresa un Y  es que si existe y se debe de insertar solo el accesorio costo cero y el num transaccciom de tbraccd
     IF substr(v_acc_costo_cero,1,1) = 'Y'  and substr(v_acc_costo_cero,3,3) >= 1 and pcve_envio != '01UF'   then
     
      VIMPORTE := 0;
      tran_number := substr(v_acc_costo_cero,3,3);
      vvalida    := substr(v_acc_costo_cero,1,1);
      ----dbms_output.put_line('evalua el regro de coto0_1  '||  VIMPORTE||'-'||  vvalida ||'-'||tran_number);
       vp_estatus := 'PA';
       -- insert into twpasow( valor1, valor2, valor3, valor4, valor5)
        --values ('func_insrt_serv_cumple 3 condiciones',ppidm,pcode, pcve_envio, v_acc_costo_cero  );
        ----dbms_output.put_line('evalua el regro de coto0_2  '||  VIMPORTE||'-'||  vvalida ||'-'||tran_number);
      elsif substr(v_acc_costo_cero,1,1) = 'Y'  and substr(v_acc_costo_cero,3,3) >= 1 and pcve_envio = '01UF'  then
      VIMPORTE := 0;
      tran_number := substr(v_acc_costo_cero,3,3);
      vvalida    := substr(v_acc_costo_cero,1,1);
      vp_estatus := 'AC';
      ----dbms_output.put_line('evalua el regro de coto0_3  '||  VIMPORTE||'-'||  vvalida ||'-'||tran_number);
       -- insert into twpasow( valor1, valor2, valor3, valor4, valor5)
        --values ('func_insrt_serv_NO_cumple las condiciones',ppidm,pcode, pcve_envio, v_acc_costo_cero  );



      end if;

         ---nueva validacion para los accesorios de ABCC que no llevan costos estan en un parametrizador
    begin
          select COUNT(1)
            INTO VVAL
            from ZSTPARA
            where 1=1
            and ZSTPARA_MAPA_ID ='PROCESO_AUTOSER'
            AND  ZSTPARA_PARAM_ID  = PCODE ;
    exception when others then
      VVAL  := 0;
    end;


        IF VVAL >= 0 THEN
        vvalida :='Y'; --QUIERE DECIR QUE SI TIENE VALOR CERO
         
        ELSE
        vvalida :='N' ;-- ESTE ACCESORIO SI TIENE VALOR

        END IF;

       --- nueva validación proyecto benefios GRATIS cote y caps al momento de tener tu COLF.-- 26.07.022
    -- SI regresa exito entonces asiga valor a la variable para marcar el acc y que no pueda pedir otro mas gratis
    --- se cambia por este para DOC_COST_0
      begin
          select 'Y'
            into vval_benef
            from zstpara
             where 1=1
               and ZSTPARA_MAPA_ID   = 'DOC_COST_0'
               and ZSTPARA_PARAM_VALOR  = pcode;

      exception when others then
       vval_benef := 'N';
      end;

    IF vval_benef = 'Y' THEN
                VSTEP :=  PKG_SERV_SIU.F_ACC_GIFT  (PPIDM,PCODE,pprograma );
      -- --dbms_output.put_line('despues de acc_gift  '|| VSALIDA ||'-'|| VSTEP );

        IF VSTEP = 'EXITO'  THEN

            VSTEP := 'BNFTS';
            vp_estatus  := 'CL';
            vvalida :='Y'; --QUIERE DECIR QUE SI TIENE VALOR CERO


        ELSE
           NULL;
           VSTEP := null;
        END IF;

     end if;
     ----dbms_output.put_line('despues de acc_gift  '|| VSALIDA ||'-'|| VSTEP||'-'|| vvalida );

    --- se agrega validación para certificaciones MES GRATIS glovicx 19.08.022--
        begin

        select distinct 'Y'
          INTO vaccesorio
            from zstpara
              where 1=1
                and ZSTPARA_MAPA_ID  = 'MES_GRATIS'
                and ZSTPARA_PARAM_ID = pcode;
    exception when others then

      vaccesorio  := 'N';
     end;

   IF vaccesorio = 'Y' THEN
      vgratis  :=  PKG_SERV_SIU.F_ONE_FREE ( PPIDM, PCODE  ) ;

       IF vgratis = 'EXITO' THEN

       vvalida :='Y'; --QUIERE DECIR QUE SI TIENE VALOR CERO
       VSTEP := 'MESGRATIS';
       --vp_estatus  := 'CL';

        ELSE
        NULL;
        --vvalida :='N'; -- ESTE ACCESORIO SI TIENE VALOR

       END IF;
   END IF;
   
   ------se agrega la validacion de nive gratis en teoria si ya viene en ceros el importe desde el parametroglovicx 25092023
   IF PCODE = 'NIVE' and VIMPORTE = 0 then 
   VSTEP := 'NIVE_CERO';
     --vp_estatus  := 'CL';
      vp_estatus  := 'EC'; --nuevo estatus
     --VSALIDA := 0;
     vvalida := 'Y';
     
   end if;
   
    --dbms_output.put_line('despues de F_ONE_FREE  '|| VSALIDA ||'-'|| vgratis );



   --NUEVA VALIDACIÓN PARA LOS RECONOCIMIENTOS REJE  DE SESIONES EJECUTIVAS GLOVICX 14.10.2022
    IF  pcode  = 'REJE' THEN
      null;
           ----dbms_output.PUT_LINE('ANTES  DE REJE  '|| VREJE);
      VREJE :=    PKG_SERV_SIU.F_REJE_QR (PPIDM , PPROGRAMA , PCODE   );

      ----dbms_output.PUT_LINE('SALIENDO DE REJE servi  '|| VREJE);


     IF VREJE = 'EXITO' THEN

      vvalida  := 'Y';
      vp_estatus  := 'CL';
      ----dbms_output.PUT_LINE('valifa IF  DE REJE servi  '|| VREJE||'-'||vvalida||'-'||vp_estatus );
      ELSE
       vvalida  := 'N';
       VSALIDA  :='NO TIENE EL BENFICIO';
       ----dbms_output.PUT_LINE('valifa IFelse  DE REJE servi  '|| VREJE||'-'||vvalida||'-'||vp_estatus );
      END IF;

    END IF;

  ----  se apaga este flujo y pasa al flujo normal de certifcaciones glovicx 05.06.2023 glovicx x ordenes de fernando
  /*
      IF  pcode  = 'SENI' THEN

          ----dbms_output.PUT_LINE('valifa IF  DE SENI servi  '|| VREJE||'-'||vvalida||'-'||vp_estatus );
             vgratis  :=  PKG_SERV_SIU.F_ONE_FREE ( PPIDM, PCODE  ) ;

            --insert into twpasow( valor1, valor2, valor3, valor4, valor5)
            --values ('func_insrt_serv_mes_gratisx2:  ',ppidm,pcode, vaccesorio, vgratis  );

               IF vgratis = 'EXITO' THEN
                  vvalida  := 'Y';
                  vp_estatus  := 'CL';

                end if;

     end if;
*/

      IF  pcode  = 'DIPD' THEN  --- validación para diplomas EC costo cero QR. se tiene que poner este CL para que lo tome el procesoQR, glovicx 20.01.2023
         vvalida  := 'Y';
         vp_estatus  := 'CL';
      end if;

      ----dbms_output.put_line('despues de F_REJE_QR  '|| vvalida ||'-'|| VREJE );
             IF PCODE  in ('CPRE','CLRE' ) and VIMPORTE = 0 then  ---esto es para las cartas SS costo cero glovicx 03.12.2024
                 vp_estatus  := 'PA';
                 vvalida := 'Y';
                 
             end if;
             

  IF   TO_NUMBER(VIMPORTE) > 0  OR  vvalida = 'Y'  THEN
     -- dbms_output.put_line('estoy dentro del if la validacion  '||  vvalida ||'-'|| vsalida  );



      BEGIN
            SELECT svrsvpr_seq_no_sequence.NEXTVAL
               INTO serv
               FROM DUAL;
     EXCEPTION WHEN OTHERS THEN
     NULL;
       serv:=null;

     END;

          ----AQUI EVALUA SI EL SERVICIO SE PUEDE SOLICITAR MAS DE UNA VEZ SI LO ENCUENTRA ENTONCES SI LO DEJA PASAR
          BEGIN
                SELECT COUNT(ZSTPARA_PARAM_VALOR)
                   INTO  VP_CODEM
                    FROM SATURN.ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'SERVICIO_MULTIP'
                  AND ZSTPARA_PARAM_ID =  PCODE ;

         EXCEPTION WHEN OTHERS THEN
         NULL;
           VP_CODEM:=0;

         END;


        begin  ------ESTE ajuste se hizo para ya no tener que agregar el nivel en la columnaVPDI_CODE, aqui toma de manera natural el nivel de todos los servicios
                --  se libera para todos los codigos glovicx 25/05/021
               select  (SVRRSSO_RSRV_SEQ_NO)
                    INTO rsrv_noseq
                    FROM SVRRSSO o, SVRRSRV r
                    WHERE  1=1
                    AND o.SVRRSSO_SRVC_CODE     = R.SVRRSRV_SRVC_CODE
                    and O.SVRRSSO_RSRV_SEQ_NO   = R.SVRRSRV_SEQ_NO
                    AND o.SVRRSSO_SRVC_CODE     = pcode
                    AND o.SVRRSSO_WSSO_CODE     = pcve_envio --'NONE'
                    AND  SUBSTR(o.SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(Ppidm),1,2)
                    and r.SVRRSRV_LEVL_CODE = (select distinct SORLCUR_LEVL_CODE from sorlcur s
                                                  where sorlcur_pidm = Ppidm
                                                       and  SORLCUR_LMOD_CODE = 'LEARNER'
                                                        and SORLCUR_TERM_CODE =  (select max(SORLCUR_TERM_CODE) from sorlcur s2
                                                                                     where sorlcur_pidm = Ppidm
                                                                                      and  SORLCUR_LMOD_CODE = 'LEARNER' )  ) ;



         exception when others then

             BEGIN
                  select min (SVRRSSO_RSRV_SEQ_NO)
                    INTO rsrv_noseq
                      FROM SVRRSSO
                       WHERE  1=1
                       AND SVRRSSO_SRVC_CODE = PCODE--protocol_code_in  CDIGO DE SERVICIO
                       AND SVRRSSO_WSSO_CODE =  pcve_envio --'NONE'
                       AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(Ppidm),1,2);

              EXCEPTION WHEN OTHERS THEN
               rsrv_noseq := 1;

              END;

           rsrv_noseq := 1;

        end;

     --insert into twpasow( valor1, valor2, valor3, valor4)
           --values ( 'desp_valida COLF-rrsso 3',ppidm, pprograma, rsrv_noseq);


    --IF PCODE = 'NIVE'   then
        IF  VP_CODEM  >= 1  THEN


           VSALIDA := 0;



         ELSE

         --INSERT INTO TWPASOW(VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,VALOR6,VALOR7,VALOR8,VALOR9)
              --VALUES('WWW_SIU_F_INSRT_SERV_OTROS. 4 ', Ppidm,  PCODE,pPeriodo,  VIMPORTE, rsrv_noseq,serv,VSALIDA,SYSDATE  );
             --COMMIT;

            IF pcode = 'COLF'  THEN
                     VSALIDA :=  PKG_SERV_SIU.F_VALIDA_COLF_NIVEL (ppidm , pcode , pcampus , pprograma);
                    
             -- dbms_output.put_line('dentro de COLF:  '||  vsalida); 
                       
              ELSE
         ----aqui hace esta validacion solo cuando no sea nivelacion por que para eso esta la funcion donde se valida eso
               begin
                select count(SVRSVPR_PROTOCOL_SEQ_NO)
                INTO VSALIDA
                        from SVRSVPR  v
                        WHERE 1=1
                           and   SVRSVPR_PIDM = Ppidm
                           and  SVRSVPR_SRVS_CODE != 'CA'---NOT IN ('AC','PA')
                           and  V.SVRSVPR_SRVC_CODE  = PCODE
                           and  V.SVRSVPR_CAMP_CODE  =  PCAMPUS;

               exception when others then
               VSALIDA := '0';
              END;

             

            END IF;


        end if;


          IF pcode = 'DTMA' and VIMPORTE = 0  THEN  --------esta seccion es para producion cientifica glovicx 02.12.2024
         
          VSTEP := 'DTMA_CERO';
          vp_estatus  := 'CL';
           vvalida := 'Y';
         
         end if;



     IF VSALIDA = '0'  THEN


       begin
             insert into svrsvpr ( SVRSVPR_PROTOCOL_SEQ_NO,
                        SVRSVPR_PIDM,
                        SVRSVPR_RSRV_SEQ_NO,
                        SVRSVPR_SRVC_CODE,
                        SVRSVPR_SRVS_CODE,
                        SVRSVPR_BILLING_IND,
                        SVRSVPR_USER_ID,
                        SVRSVPR_ACTIVITY_DATE,
                        SVRSVPR_TERM_CODE,
                        SVRSVPR_ESTIMATED_DATE,
                        SVRSVPR_WSSO_CODE,   ---------esta es la cve de entrega
                        SVRSVPR_COPIES,
                        SVRSVPR_PROTOCOL_AMOUNT,
                        SVRSVPR_ACCD_TRAN_NUMBER,
                        SVRSVPR_RECEPTION_DATE,
                        SVRSVPR_DELIVERY_DATE,
                        SVRSVPR_STU_COMMENT,
                        SVRSVPR_INT_COMMENT,
                        SVRSVPR_ANSWER_COMMENT,
                        SVRSVPR_STEP_COMMENT,
                        SVRSVPR_DATA_ORIGIN,
                        SVRSVPR_ORIG_CODE,
                        SVRSVPR_CHNL_CODE,
                        SVRSVPR_RQST_CODE,
                        SVRSVPR_SURROGATE_ID,
                        SVRSVPR_VERSION,
                        SVRSVPR_VPDI_CODE,
                        SVRSVPR_STATUS_DATE,
                        SVRSVPR_CAMP_CODE  )
                           values
                            (serv,
                             Ppidm,
                             rsrv_noseq,
                             PCODE,
                             vp_estatus, ---'AC', SE CAMBIO POR EL AJUSTE DE UPSELLING 12/01/21
                             'Y',
                             'WWW_USER',
                             sysdate,
                             pPeriodo,
                             sysdate,
                             pcve_envio,
                             1,
                             VIMPORTE,
                             tran_number,
                             sysdate,
                             null,
                             PPCOMENT,
                             null,
                             null,
                             VSTEP,
                             'WWW_SIU',
                             'WEB',
                             'ELECTR',
                             null,
                             null,
                             null,
                             null,
                             sysdate,
                             PCAMPUS);
                commit;



       VSALIDA:=serv;

        RETURN   VSALIDA;

     exception when others then
       VSALIDA:='Error :'||sqlerrm;


     end;

    END IF; -- IF DE SE SI YA EXISTE UN  SERVICIO ANTERIOR

     RETURN  ('EL SERVICIO YA EXISTE O NO ESTA DISPONIBLE¡¡'); ---este regresa

    ELSE

      RETURN  (VSALIDA);

  END IF;

  RETURN   VSALIDA;


  exception when others then
       VSALIDA:='Error :'||sqlerrm;
        dbms_output.put_line('error al general tbraccd:  '|| vsalida );
         RETURN  (VSALIDA);
  end F_INSRT_SERV;



FUNCTION F_INSRT_PREGUNTAS (Pserv in NUMBER, PDL_DATA_SEQ  VARCHAR2, PDL_DATA_CODE VARCHAR2,PDL_DATA_DESC VARCHAR2 ) Return VARCHAR2
IS


VSALIDA       VARCHAR2(800):='EXITO';
VCODE         VARCHAR2(6);
VPIDM         NUMBER;


    BEGIN

/*  PSERV := 48068;
  PDL_DATA_SEQ := '3';
  PDL_DATA_CODE := 'L1E';
  PDL_DATA_DESC := '01/03/2021-AL-26/04/2021';
  */

          --CALCULO PIDM Y CODIGO
           BEGIN

            select DISTINCT SVRSVPR_SRVC_CODE, SVRSVPR_PIDM
               INTO    VCODE ,VPIDM
            from SVRSVPR  v
            WHERE 1=1
            and   SVRSVPR_PROTOCOL_SEQ_NO = Pserv
            ;

           EXCEPTION WHEN OTHERS THEN
             VCODE  := NULL;
             VPIDM  := NULL;
           END;



   IF VSALIDA='EXITO'  THEN
        ---si todo las validaciones que se hicieron chuy chuy son validas o no entro al if inicial inserta la pregunta
         -----  NO ES SESION EJECUTIVA SIGUE FLUJO NORMAL   AQUI ENTRAN EL 99% DE LOS ACCESORIOS...
            insert into SVRSVAD (SVRSVAD_PROTOCOL_SEQ_NO,
                SVRSVAD_ADDL_DATA_SEQ,
                SVRSVAD_ADDL_DATA_CDE,
                SVRSVAD_ADDL_DATA_DESC,
                SVRSVAD_USER_ID,
                SVRSVAD_ACTIVITY_DATE,
                SVRSVAD_DATA_ORIGIN,
                SVRSVAD_SURROGATE_ID,
                SVRSVAD_VERSION,
                SVRSVAD_VPDI_CODE )
          VALUES (Pserv,
                  PDL_DATA_SEQ,   ----valor secuencia de la funcion de  c/u de los  campos
                  --substr(PDL_DATA_CODE, 1,instr(PDL_DATA_CODE,'|',1)-1) ,  ----valor codigo del combo que el usuario escogio segun campo
                  substr(decode( instr(PDL_DATA_CODE,'|',1),0,PDL_DATA_CODE,substr(PDL_DATA_CODE, 1,instr(PDL_DATA_CODE,'|')-1)  ),1,12), -- SIMPRE VA A 12 ES EL LARGO DE LA COLM
                  PDL_DATA_DESC,  ----valor descripcion  del combo que el usuario escogio según campo
                  'WWW_USER',
                  SYSDATE,
                  'SIU_SSB',
                  NULL,
                  NULL,
                  NULL
                  );


                VSALIDA:='EXITO';




       COMMIT;  --GENERAL PARA TODOS LOS CASOS Y PREGUNTAS
       RETURN   VSALIDA;

   ELSE
       ROLLBACK;
       RETURN   VSALIDA;

   END IF;



 exception when others then
   VSALIDA:='Error :'|| substr(sqlerrm,1,490);


    RETURN   VSALIDA;

END F_INSRT_PREGUNTAS;


FUNCTION F_PROGRAM (PCODE VARCHAR2, PPIDM NUMBER   ) Return VARCHAR2  IS


 CONTADOR  NUMBER:=1;
 VSALIDA   varchar2(300);

BEGIN
 --**REGRESA EL PROGRAMA QUE TIENE ASIGNADO EL ALUMNO
--      SELECT COUNT (*)
--        INTO contador
--        FROM svrsrad
--       WHERE     svrsrad_srvc_code = PCODE
--             AND (   svrsrad_addl_data_title LIKE '%PROGRAM%'
--                  OR svrsrad_addl_data_title LIKE '%Program%');

      IF contador > 0
      THEN
         DELETE FROM szbstdn2
               WHERE z_pidm = Ppidm;
        ---    --dbms_output.put_line('si encuentra' || contador);

         IF PCODE NOT IN ('CACO', 'CAAR')
         THEN
            INSERT INTO szbstdn2
               SELECT DISTINCT
                         z.sgbstdn_program_1        programa,
                         RPAD (ZZ.SZTDTEC_PROGRAMA_COMP, 60, ' ')
                      || '||'
                      || SUBSTR (v.stvstst_desc, 1, 8)
                      || '||PLAN'
                      || ' 20'
                      || DECODE (SUBSTR (z.sgbstdn_term_code_ctlg_1, 3, 2),
                                 '00', '11',
                                 SUBSTR (z.sgbstdn_term_code_ctlg_1, 3, 2))
                         program_desc,
                      Ppidm
              FROM sgbstdn z,
                   stvstst v,
                   sztdtec zz
                WHERE  1=1
                   and z.sgbstdn_pidm = Ppidm
                   AND z.sgbstdn_program_1 = zz.SZTDTEC_PROGRAM
                   AND z.sgbstdn_stst_code = v.stvstst_code
                   and z.sgbstdn_stst_code != 'CP'
                   AND z.sgbstdn_term_code_eff IN
                             (SELECT MAX (x.sgbstdn_term_code_eff)
                                FROM sgbstdn x
                               WHERE     z.sgbstdn_pidm = x.sgbstdn_pidm
                                    AND z.sgbstdn_program_1 =   x.sgbstdn_program_1
                                    --AND z.sgbstdn_term_code_ctlg_1 =  x.sgbstdn_term_code_ctlg_1
                                 );
         ELSE
         
            INSERT INTO szbstdn2
               SELECT DISTINCT
                         z.sgbstdn_program_1  programa,
                         RPAD (ZZ.SZTDTEC_PROGRAMA_COMP , 60, ' ')|| '||' || j.stvmajr_desc as  program_desc,
                         z.sgbstdn_pidm
                 FROM sgbstdn z,
                      stvstst v,
                      stvmajr j,
                      sztdtec zz
                WHERE  1=1   
                      and z.sgbstdn_pidm = Ppidm
                      AND z.sgbstdn_program_1 = zz.SZTDTEC_PROGRAM
                      AND z.sgbstdn_stst_code = v.stvstst_code
                      AND z.sgbstdn_term_code_eff IN
                             (SELECT MAX (x.sgbstdn_term_code_eff)
                                FROM sgbstdn x
                               WHERE 1=1    
                                    and z.sgbstdn_pidm = x.sgbstdn_pidm
                                    AND z.sgbstdn_program_1 = x.sgbstdn_program_1
                                    --AND z.sgbstdn_term_code_ctlg_1 =  x.sgbstdn_term_code_ctlg_1--- ajuste para que solo regrese el ultimo glovicx 12.02.2025
                                    )
                      AND sgbstdn_majr_code_1 = stvmajr_code;
         END IF;

         COMMIT;
      END IF;


         COMMIT;
    

     VSALIDA   := 'EXITO';

    RETURN   VSALIDA;

   Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
            VSALIDA:='Error :'||sqlerrm;

    RETURN   VSALIDA;

END F_PROGRAM;


FUNCTION F_PERIODO (PCODE VARCHAR2 , PPIDM NUMBER ) Return VARCHAR2  IS


 CONTADOR  NUMBER;
 VSALIDA   varchar2(300);

BEGIN
      SELECT COUNT (*)
        INTO contador
        FROM svrsrad
       WHERE     svrsrad_srvc_code = PCODE
             AND (   svrsrad_addl_data_title LIKE '%PERIODO%'
                  OR svrsrad_addl_data_title LIKE '%Periodo%');

      IF contador > 0
      THEN
         DELETE FROM periodo2
          WHERE PIDM = PPIDM;

         INSERT INTO periodo2
              SELECT DISTINCT stvterm_code codigo, stvterm_desc periodo, SPRIDEN_PIDM PIDM
                FROM stvterm, sobptrm, spriden
               WHERE  1=1
               --   sobptrm_ptrm_code = '1'
                     AND (   TRUNC (SYSDATE) BETWEEN TRUNC (sobptrm_start_date)
                                                 AND TRUNC (sobptrm_end_date)
                          OR (TRUNC (sobptrm_start_date) > TRUNC (SYSDATE)))
                     AND sobptrm_term_code = stvterm_code
                     AND spriden_pidm = PPIDM
                     AND SUBSTR (stvterm_code, 1, 2) =  SUBSTR (spriden_id, 1, 2)
                     and  SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
            ORDER BY stvterm_code;

         COMMIT;
      END IF;

     VSALIDA   := 'EXITO';

    RETURN   VSALIDA;

Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error :'||sqlerrm;

    RETURN (VSALIDA);

END F_PERIODO;

FUNCTION F_PTE_PERIODO (PPIDM NUMBER, pcode varchar2 ) Return VARCHAR2  IS


 CONTADOR  NUMBER;
 VSALIDA   varchar2(300);
 -- pcode   varchar2(4):= 'EXTR';
  nvparte  varchar2(40);
  VFINI     varchar2(14);
  vpantes    date; --varchar2(14);
  vdesps      DATE; --varchar2(14);
  vestatus     varchar2(3);
  vdias_desp     number:=0;
  valor_dias     number:=0;
  VBITACORA     varchar2(30);
   vnivel        varchar2(4);
  VDIAS_DIF     NUMBER:=0;
  VCERTIFICA   varchar2(1):= 'N';
  vhack        varchar2(1):= 'N';


BEGIN




  IF pcode = 'EXTR'  then
      nvparte := 81||','||82||','||83;

      ELSIF   PCODE  = 'TISU' then
      nvparte := '84'||','||'85'||','||'86';

  END IF;

------validamos si es una certificacion de gece
        begin
           select distincT 'Y'
               INTO VCERTIFICA
               from sztgece
                 WHERE 1=1
                 AND SZT_CODE_SERV = PCODE;

        exception when others then
         VCERTIFICA := 'N';
        end;


     begin
       DELETE FROM partep2
        WHERE PIDM = PPIDM;
         commit;
     exception when others then
       null;
     end;



   IF pcode = 'EXTR'  then

      --liberar este cambio Unika 2.0 29/01/021 glovicx
               begin
                 select (to_date(VFINI, 'DD/MM/YYYY') - ZSTPARA_PARAM_VALOR)  antes
                  INTO vpantes
                 from zstpara
                where 1=1
                and ZSTPARA_MAPA_ID in ('ANTES_EXAM_UNIC' );
                exception when others then
                   vpantes :=null;
                   ----dbms_output.put_line( 'error en calcula parametro antes:  '|| sqlerrm );
                   -- insert into twpasow(valor1, valor2, valor3)
                   -- values( 'error antes calcula parametro:EXTR ::', pcode, VFINI   ); commit;
                end;


                begin
                select  ZSTPARA_PARAM_VALOR dias
                INTO  vdias_desp
                from zstpara
                where 1=1
                and ZSTPARA_MAPA_ID in ('DESP_EXAM_UNIC' );

                exception when others then
                   vdias_desp := 2;
                   ----dbms_output.put_line( 'error en calcula parametro desp: '|| sqlerrm );
                   -- insert into twpasow(valor1, valor2, valor3)
                   -- values( 'error despues calcula parametro:EXTR ::', pcode, VFINI   ); commit;
                end;


             ---------aqui saca los valores de de la fecha inicio que va ser el pivote para los parametrizadores para ofertar dias antes y dias despues glovicx 09/12/2020
            begin


                 select to_char(SOBPTRM_START_DATE, 'DD/MM/YYYY') FINI
                    into VFINI
                      from sobptrm
                    where 1=1
                    and SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                    AND LENGTH (SOBPTRM_PTRM_CODE) = 3
                    --and  sobptrm_ptrm_code   = TRIM(vpparte)
                   -- AND  trunc(sysdate)  BETWEEN TRUNC (sobptrm_start_date)   AND TRUNC (sobptrm_end_date)
                    and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                    and substr(SOBPTRM_DESC,1,3) = (select distinct decode(SFRSTCR_LEVL_CODE,'MS', 'MAS','MA','MAE','LI','LIC' )
                                                                          from sfrstcr  rr
                                                                          where rr.SFRSTCR_PIDM = Ppidm
                                                                          and rr.SFRSTCR_TERM_CODE = (select max(cc.SFRSTCR_TERM_CODE)
                                                                                                   from sfrstcr cc
                                                                                                    where cc.SFRSTCR_PIDM = rr.SFRSTCR_PIDM)   )
                    AND  substr(sobptrm_term_code,5,2) in ('81','82','83')
                    and trunc (SOBPTRM_START_DATE)+vdias_desp >= TRUNC(SYSDATE)
                    AND ROWNUM < 2
                    ORDER BY 1 DESC;

              exception when others then

               VFINI :=null;
               vsalida := sqlerrm;
             --  --dbms_output.put_line( 'error en calcula fecha ini'|| sqlerrm );

              --VBITACORA := F_BITSIU(  F_GetSpridenID(ppidm),pPIDM,pcode,NULL,NULL,NULL,'f_pte_periodo_EXTRA',SYSDATE,user,NULL,NULL,NULL,NULL,
                               -- NULL,NULL,NULL,NULL,'no escuentra parte period0',vsalida,NULL,NULL,NULL,NULL );commit;

            end;

            begin
                 select (to_date(VFINI, 'DD/MM/YYYY') - ZSTPARA_PARAM_VALOR)  antes
                  INTO vpantes
                 from zstpara
                where 1=1
                and ZSTPARA_MAPA_ID in ('ANTES_EXAM_UNIC' );
                exception when others then
                   vpantes :=null;
                   ----dbms_output.put_line( 'error en calcula parametro antes:  '|| sqlerrm );
                   -- insert into twpasow(valor1, valor2, valor3)
                   -- values( 'error antes calcula parametro:EXTR ::', pcode, VFINI   ); commit;
                end;

            --   insert into twpasow(valor1, valor2, valor3)
            --     values( 'fechas antes calcula parametro:EXTR ::', pcode, vpantes   ); commit;

                begin
                select (to_date(VFINI, 'DD/MM/YYYY') + ZSTPARA_PARAM_VALOR)  desp, ZSTPARA_PARAM_VALOR dias
                INTO vdesps, vdias_desp
                from zstpara
                where 1=1
                and ZSTPARA_MAPA_ID in ('DESP_EXAM_UNIC' );

                exception when others then
                   vdesps :=null;
                   ----dbms_output.put_line( 'error en calcula parametro desp: '|| sqlerrm );
                   -- insert into twpasow(valor1, valor2, valor3)
                   -- values( 'error despues calcula parametro:EXTR ::', pcode, VFINI   ); commit;
                end;



       --IF TO_CHAR(sysdate, 'DD/MM/YYYY') between TO_CHAR(vpantes, 'DD/MM/YYYY') and TO_CHAR(vdesps,'DD/MM/YYYY')  then
       IF   trunc(sysdate)  between (vpantes) and (vdesps) then

          --    insert into twpasow(valor1, valor2, valor3, valor4)
          --            values('dentro de la  validación rango de fechas', vpantes , VFINI, vdesps   );
          --            commit;


        INSERT INTO partep2(CODE, Partep_DESC,PIDM)
        select  datos.codigo , datos.Partep_DESC , PPIDM
        from (
        SELECT DISTINCT SO.SOBPTRM_PTRM_CODE codigo,
            --( substr(SO.SOBPTRM_PTRM_CODE,2,2))  mes,
             to_char(SOBPTRM_START_DATE, 'DD/MM/YYYY')||'-AL-'||to_char(SOBPTRM_END_DATE, 'DD/MM/YYYY') as Partep_DESC
          -- , ;pidm pidm
             ,sobptrm_start_date
             ,sobptrm_end_date
             FROM stvterm, sobptrm  SO ---, spriden
               WHERE     SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                     AND LENGTH (SOBPTRM_PTRM_CODE) = 3
                     --AND   ( trunc(sysdate)  BETWEEN TRUNC (sobptrm_start_date)   AND TRUNC (sobptrm_end_date) )
                     AND sobptrm_term_code = stvterm_code
                     and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                      and substr(sobptrm_term_code,5,2) in (81,82,83)
                     and substr(SOBPTRM_DESC,1,3) = (select distinct decode(SFRSTCR_LEVL_CODE,'MS', 'MAS','MA','MAE','LI','LIC' )
                                                                          from sfrstcr  rr
                                                                          where SFRSTCR_PIDM = Ppidm
                                                                          and SFRSTCR_TERM_CODE = (select max(SFRSTCR_TERM_CODE)
                                                                                                   from sfrstcr cc
                                                                                                    where cc.SFRSTCR_PIDM = rr.SFRSTCR_PIDM)   )

                     and trunc(SOBPTRM_START_DATE)+vdias_desp >= trunc(sysdate)

                        order by sobptrm_start_date
                     )  datos
                where 1=1
                 and rownum <= 1
                 ;
       end if;

   ELSIF pcode  = 'TISU'  then

          begin
              null;
                SELECT DATOS.FINI
                    into VFINI
                    FROM (
                    select (SOBPTRM_START_DATE) FINI
                     from sobptrm
                    where 1=1
                    and  SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                    AND LENGTH (SOBPTRM_PTRM_CODE) = 3
                    --AND  trunc(sysdate)  BETWEEN TRUNC (sobptrm_start_date)   AND TRUNC (sobptrm_end_date)
                    and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                    and substr(SOBPTRM_DESC,1,3) = (select distinct decode(SFRSTCR_LEVL_CODE,'MS', 'MAS','MA','MAE','LI','LIC' )
                                                              from sfrstcr  rr
                                                              where SFRSTCR_PIDM = Ppidm
                                                              and SFRSTCR_TERM_CODE = (select max(SFRSTCR_TERM_CODE)
                                                                                       from sfrstcr cc
                                                                                        where cc.SFRSTCR_PIDM = rr.SFRSTCR_PIDM)   )

                    AND  substr(sobptrm_term_code,5,2) in (84,85,86)
                    ) DATOS
                    WHERE 1=1
                    AND trunc(DATOS.FINI)+vdias_desp >= TRUNC(SYSDATE)
                    and rownum < 1
                    ;



              exception when others then

               VFINI :=null;
                vsalida := sqlerrm;
               --VBITACORA := F_BITSIU(  F_GetSpridenID(ppidm),pPIDM,pcode,NULL,NULL,NULL,'f_pte_periodo_TISU',SYSDATE,user,NULL,NULL,NULL,NULL,
                               -- NULL,NULL,NULL,NULL,'no escuentra parte period0',vsalida,NULL,NULL,NULL,NULL );commit;


            end;

                 begin
                 select to_date(VFINI) - ZSTPARA_PARAM_VALOR  antes
                  INTO vpantes
                 from zstpara
                where 1=1
                and ZSTPARA_MAPA_ID in ('ANTES_EXAM_UNIC' );
                exception when others then
                   vpantes :=null;
                end;


                begin
                select to_date(VFINI) + ZSTPARA_PARAM_VALOR  desp
                INTO vdesps
                from zstpara
                where 1=1
                and ZSTPARA_MAPA_ID in ('DESP_EXAM_UNIC' );
                exception when others then
                   vdesps :=null;
                end;





     IF trunc(sysdate) between vpantes and vdesps  then


        INSERT INTO partep2(CODE, Partep_DESC,PIDM)
        select  datos.codigo , datos.Partep_DESC , PPIDM
        from (
        SELECT DISTINCT SO.SOBPTRM_PTRM_CODE codigo,
            --to_number( substr(SO.SOBPTRM_PTRM_CODE,2,2))  mes,
             to_char(SOBPTRM_START_DATE, 'DD/MM/YYYY')||'-AL-'||to_char(SOBPTRM_END_DATE, 'DD/MM/YYYY') as Partep_DESC
          -- , ;pidm pidm
             ,sobptrm_start_date
             ,sobptrm_end_date
             FROM stvterm, sobptrm  SO ---, spriden
               WHERE     SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                     AND LENGTH (SOBPTRM_PTRM_CODE) = 3
                   --  AND   (trunc(sysdate)  BETWEEN TRUNC (sobptrm_start_date)   AND TRUNC (sobptrm_end_date) )
                     AND sobptrm_term_code = stvterm_code
                     and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                      and substr(sobptrm_term_code,5,2) in (84,85,86)
                     and substr(SOBPTRM_DESC,1,3) = (select distinct decode(SFRSTCR_LEVL_CODE,'MS', 'MAS','MA','MAE','LI','LIC' )
                                                                          from sfrstcr  rr
                                                                          where SFRSTCR_PIDM = Ppidm
                                                                          and SFRSTCR_TERM_CODE = (select max(SFRSTCR_TERM_CODE)
                                                                                                   from sfrstcr cc
                                                                                                    where cc.SFRSTCR_PIDM = rr.SFRSTCR_PIDM)   )
                    and sobptrm_start_date + vdias_desp >= TRUNC(SYSDATE)
                    order by sobptrm_start_date
                     )  datos
        where 1=1
         and rownum <= 1
         ;


      END IF;


    ELSIF VCERTIFICA = 'Y'  THEN -- se cambio x esta opción glovicx 18.11.022
   --ELSIF pcode  IN ('COLI','COMA','COMM','CNLI', 'CNMA' ,'CNMS','CNDO','UNLI', 'UNMA' ,'UNMM', 'FACE', 'MICR', 'GOAD', 'CIFA','GOCL','MUBA','UCAM','TABL')  then
   --este segmento es para cursera, UNICEF Y CONECT  que es igual a upselling pero sin sztalol
       begin
             select distinct p1.nivel
              INTO  vnivel
             from tztprog p1
             where 1=1
             and p1.pidm = ppidm
             and p1.sp = (select max(p2.sp) from  tztprog p2  where 1=1 and p1.pidm =p2.pidm);
        exception when others then
        vnivel  := null;
        end;


        begin
          SELECT DISTINCT ZSTPARA_PARAM_VALOR
            into VDIAS_DIF
            FROM ZSTPARA
            WHERE 1=1
            AND ZSTPARA_MAPA_ID = 'UPSELLING'
            and SUBSTR(ZSTPARA_PARAM_DESC,1,2)  = DECODE(vnivel,'MS','MA',vnivel);

        EXCEPTION WHEN OTHERS THEN
        VDIAS_DIF := 0;
        end;


     IF pcode = 'HKTN'  then 
        --- aqui ponemos la ocion de HACKATHON por que se maneja de forma especial-- 
        --  ya que no se puede presentar la misma fecha que esta en rango si ya compro el accesorio--
      
          begin
            select 'Y'
                 INTO vhack
                from svrsvpr v,SVRSVAD VA
                 where 1=1
                  and SVRSVPR_SRVC_CODE = pcode
                  AND v.SVRSVPR_PIDM    = ppidm
                  and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                  and va.SVRSVAD_ADDL_DATA_SEQ = '7'
                  and trunc(sysdate) between ( substr(va.SVRSVAD_ADDL_DATA_DESC,1,instr(va.SVRSVAD_ADDL_DATA_DESC,'-')-1))
                       and (substr(va.SVRSVAD_ADDL_DATA_DESC,instr(va.SVRSVAD_ADDL_DATA_DESC,'AL')+3  )) 
                  and v.SVRSVPR_PROTOCOL_SEQ_NO = (select max(v2.SVRSVPR_PROTOCOL_SEQ_NO)  
                                                     from  svrsvpr v2,SVRSVAD VA2
                                                         where 1=1
                                                          and v2.SVRSVPR_SRVC_CODE = v.SVRSVPR_SRVC_CODE 
                                                          AND v2.SVRSVPR_PIDM      = v.SVRSVPR_PIDM
                                                          and V2.SVRSVPR_PROTOCOL_SEQ_NO  = VA2.SVRSVAD_PROTOCOL_SEQ_NO
                                                          and va2.SVRSVAD_ADDL_DATA_SEQ = va.SVRSVAD_ADDL_DATA_SEQ
                  );

          
          EXCEPTION WHEN OTHERS THEN
          null;
          vhack := 'N';
          end;

      end if;
         -- dbms_output.put_line('despues de valida hack  '||  vhack );
     IF vhack = 'Y' then
     ------vamos a borrar la tabla de paso por si las flaihs
        begin
            DELETE FROM partep2
             WHERE PIDM = PPIDM;
              commit;
         exception when others then
           null;
        end;
     
     
     
     null;
     -- dbms_output.put_line('despues de valida hack es SII '||  vhack );
     
     else
       --dbms_output.put_line('despues de valida hack es NOO '||  vhack );
       
           INSERT INTO partep2(CODE, Partep_DESC,PIDM)
              select  datos.codigo , datos.Partep_DESC , PPIDM
                from (
                SELECT DISTINCT SO.SOBPTRM_PTRM_CODE codigo,
                      to_char(SOBPTRM_START_DATE, 'DD/MM/YYYY')||'-AL-'||to_char(SOBPTRM_END_DATE, 'DD/MM/YYYY') as Partep_DESC
                      ,sobptrm_start_date
                     ,sobptrm_end_date
                      ,SO.SOBPTRM_TERM_CODE term
                     FROM stvterm, sobptrm  SO ---, spriden
                       WHERE   1 = 1
                             AND  (SOBPTRM_PTRM_CODE) in (SELECT ZSTPARA_PARAM_ID
                                                            FROM ZSTPARA
                                                            WHERE 1=1
                                                            AND ZSTPARA_MAPA_ID = 'UPSELLING' )
                             AND TRUNC (sobptrm_start_date) > trunc(sysdate) - VDIAS_DIF --AQUI SE RESTAN LOS DIAS DEL PARAMETRIZADOR
                             AND sobptrm_term_code = stvterm_code
                             and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                             and substr(SOBPTRM_DESC,1,3) = (select distinct decode(SFRSTCR_LEVL_CODE,'MS', 'MAS','MA','MAE','LI','LIC','DO','DOC' )
                                                                                  from sfrstcr  rr
                                                                                  where SFRSTCR_PIDM = Ppidm
                                                                                  and SFRSTCR_TERM_CODE = (select max(SFRSTCR_TERM_CODE)
                                                                                                           from sfrstcr cc
                                                                                                            where cc.SFRSTCR_PIDM = rr.SFRSTCR_PIDM)   )
                    order by sobptrm_start_date
                      )  datos
                where 1=1
                and rownum <= 1
                order by 2;
      end if;



   ELSIF pcode  IN ('SEJL','SEJM', 'CELI','CEMA')  then
   NULL;   ------------------OJO ME FALTALA REGLA DE LOS DIAS ADICIONALES PARA PRESENTAR LA PARTEP ( FINICIO + NUMDIAS)

   --------valida que no tenga una compra activa de este mismo accesorio
   --    segun la regla de Fernando si esta el estatus como "A"  no se presentan fechas por que ya existe para ese alumno  glovicx 13/01/21
        begin
           SELECT SZTALOL_ESTATUS
               into vestatus
             FROM sztalol
                where 1=1
                and SZTALOL_PIDM = PPIDM;

        exception when others then
        vestatus := 'xx';
        end;

         begin
             select distinct p1.nivel
              INTO  vnivel
             from tztprog p1
             where 1=1
             and p1.pidm = ppidm
             and p1.sp = (select max(p2.sp) from  tztprog p2  where 1=1 and p1.pidm =p2.pidm);
        exception when others then
        vnivel  := null;
        end;

   --si esta con estatus "A" no muestars fechas  regla de fernando
        begin
          SELECT DISTINCT ZSTPARA_PARAM_VALOR
            into VDIAS_DIF
            FROM ZSTPARA
            WHERE 1=1
            AND ZSTPARA_MAPA_ID = 'UPSELLING'
            and SUBSTR(ZSTPARA_PARAM_DESC,1,2)  = DECODE(vnivel,'MS','MA',vnivel);

        EXCEPTION WHEN OTHERS THEN
        VDIAS_DIF := 0;
        end;
   --  IF vestatus != 'A' then

           INSERT INTO partep2(CODE, Partep_DESC,PIDM)
              select  datos.codigo , datos.Partep_DESC , PPIDM
                from (
                SELECT DISTINCT SO.SOBPTRM_PTRM_CODE codigo,
                      to_char(SOBPTRM_START_DATE, 'DD/MM/YYYY')||'-AL-'||to_char(SOBPTRM_END_DATE, 'DD/MM/YYYY') as Partep_DESC
                      ,sobptrm_start_date
                     ,sobptrm_end_date
                      ,SO.SOBPTRM_TERM_CODE term
                     FROM stvterm, sobptrm  SO ---, spriden
                       WHERE   1 = 1
                             AND  (SOBPTRM_PTRM_CODE) in (SELECT ZSTPARA_PARAM_ID
                                                            FROM ZSTPARA
                                                            WHERE 1=1
                                                            AND ZSTPARA_MAPA_ID = 'UPSELLING' )
                             AND TRUNC (sobptrm_start_date) > trunc(sysdate) - VDIAS_DIF --AQUI SE RESTAN LOS DIAS DEL PARAMETRIZADOR
                             AND sobptrm_term_code = stvterm_code
                             and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                             and substr(SOBPTRM_DESC,1,3) = (select distinct decode(SFRSTCR_LEVL_CODE,'MS', 'MAS','MA','MAE','LI','LIC' )
                                                                                  from sfrstcr  rr
                                                                                  where SFRSTCR_PIDM = Ppidm
                                                                                  and SFRSTCR_TERM_CODE = (select max(SFRSTCR_TERM_CODE)
                                                                                                           from sfrstcr cc
                                                                                                            where cc.SFRSTCR_PIDM = rr.SFRSTCR_PIDM)   )

                                and not exists ( select 1 from  sztalol za
                                                    where 1=1
                                                    and za.SZTALOL_PIDM = Ppidm
                                                   -- and za.SZTALOL_ESTATUS != 'A'
                                                    and za.SZTALOL_FECHA_INICIO = so.SOBPTRM_START_DATE
                                                     )
                                order by sobptrm_start_date
                      )  datos
                where 1=1
                and rownum <= 1
                order by 2;

    --  end if;

   ELSIF  pcode  = 'VOXY'   THEN

      BEGIN
        INSERT INTO partep2(CODE, Partep_DESC,pidm)
        select SOBPTRM_PTRM_CODE , to_char(SOBPTRM_START_DATE, 'DD/MM/YYYY')||'-AL-'||to_char(SOBPTRM_END_DATE, 'DD/MM/YYYY') as Partep_DESC, PPIDM
             from sobptrm
              where 1=1
                --and SOBPTRM_TERM_CODE = '022210' VALIDAR SI HAY UN PATRON PARA ESTOS PERIODOS
                and SOBPTRM_PTRM_CODE  like ('I3%')
                and trunc(sysdate) < trunc(SOBPTRM_START_DATE)
                AND ROWNUM <= 3;

      EXCEPTION  WHEN OTHERS THEN
       NULL;

      END;

   ELSIF  pcode  = 'NIVG'   THEN -- PARA NIVELACIONES EN INGLES 09.11.2022
            begin
              INSERT INTO partep2(CODE, Partep_DESC,PIDM)
                select  datos.codigo , datos.Partep_DESC , PPIDM
                from (
                SELECT DISTINCT SO.SOBPTRM_PTRM_CODE codigo,
                    --to_number( substr(SO.SOBPTRM_PTRM_CODE,2,2))  mes,
                     to_char(SOBPTRM_START_DATE, 'MM/DD/YYYY')||'-TO-'||to_char(SOBPTRM_END_DATE, 'MM/DD/YYYY') as Partep_DESC
                  -- , ;pidm pidm
                     ,sobptrm_start_date
                     ,sobptrm_end_date
                      ,SO.SOBPTRM_TERM_CODE term
                     FROM stvterm, sobptrm  SO ---, spriden
                       WHERE     SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                             AND LENGTH (SOBPTRM_PTRM_CODE) = 3
                           --  AND   ( trunc(sysdate)+1  BETWEEN TRUNC (sobptrm_start_date)   AND TRUNC (sobptrm_end_date)  --SE QUITO TODO SE VA AL NEXT LUNES 19/04/021 GLOVICX
                           --         OR (TRUNC (sobptrm_start_date) > trunc(sysdate)  ) )
                               AND   TRUNC (sobptrm_start_date) >= trunc(sysdate)  ---ESTA LINEA SE AGREGO POR EL NUEVO CAMBIO TODO SE VA A LUNES GLOVICX 1904021
                             AND sobptrm_term_code = stvterm_code
                             and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                             -- and substr(sobptrm_term_code,5,2) in (''||nvparte )
                             and substr(SOBPTRM_DESC,1,3) = (select distinct decode(SFRSTCR_LEVL_CODE,'MS', 'MAS','MA','MAE','LI','LIC' )
                                                                                  from sfrstcr  rr
                                                                                  where SFRSTCR_PIDM = Ppidm
                                                                                  and SFRSTCR_TERM_CODE = (select max(SFRSTCR_TERM_CODE)
                                                                                                           from sfrstcr cc
                                                                                                            where cc.SFRSTCR_PIDM = rr.SFRSTCR_PIDM)   )

                                order by sobptrm_start_date
                             )  datos
                where 1=1
                and rownum <= 10
                 ;
            exception when others then
                null;
               --dbms_output.put_line( 'ERROR EN NIVG CALCULA PPERIODO'||  sqlerrm);

            end;

            
   ELSIF  pcode  = 'DTMA'   THEN -- seccion para produccion cientifica DTMA glovicx 03.01.2025
   
    --dbms_output.put_line('estoy dentro de producion cientifica '|| pcode  );
   
             begin
              INSERT INTO partep2(CODE, Partep_DESC,PIDM)
                select  datos.codigo , datos.Partep_DESC , PPIDM
                from (
                   SELECT DISTINCT SO.SOBPTRM_PTRM_CODE codigo,
                       to_char(so.SOBPTRM_START_DATE, 'DD/MM/YYYY') Partep_DESC,--||'-TO-'||to_char(so.SOBPTRM_END_DATE, 'MM/DD/YYYY') as Partep_DESC
                       so.sobptrm_start_date
                       ,so.sobptrm_end_date
                       ,SO.SOBPTRM_TERM_CODE term
                       FROM stvterm, sobptrm  SO ---, spriden
                       WHERE 1=1    
                         and SUBSTR (so.SOBPTRM_TERM_CODE, 5, 1) = '7'-- esta terminacion en 7 es para las asesorias de titulacion
                         AND LENGTH (so.SOBPTRM_PTRM_CODE) = 3
                         AND TRUNC (so.sobptrm_start_date) >= trunc(sysdate)
                         AND so.sobptrm_term_code = stvterm_code
                         and substr(so.SOBPTRM_TERM_CODE,1,2)  = substr(F_GetSpridenID(Ppidm),1,2)
                         and substr(SO.SOBPTRM_PTRM_CODE,1,1)  = (select distinct decode(SFRSTCR_LEVL_CODE,'DO', 'O','MA','M' )
                                                                      from sfrstcr  rr
                                                                      where SFRSTCR_PIDM = Ppidm
                                                                      and SFRSTCR_TERM_CODE = (select max(SFRSTCR_TERM_CODE)
                                                                                               from sfrstcr cc
                                                                                                where cc.SFRSTCR_PIDM = rr.SFRSTCR_PIDM)   )

                           order by so.SOBPTRM_START_DATE
                )  datos
                where 1=1
                and rownum <= 2
                order by datos.codigo 
                 ;
            exception when others then
                null;
               --dbms_output.put_line( 'ERROR EN NIVG CALCULA PPERIODO'||  sqlerrm);

            end;


   ELSE -- ESTE EL EL NORMAL DE UTL  NIVELACION-- SE PIDIO UN CAMBIO 19/04/021 QUE TODO SE VAYA AL PROXIMO LUNES LAS NIVELACIONES GLOVICX

      -- insert into taismgr.twpaso(valor1, valor2, valor3)
      -- values( 'inserta_pte_periodo UTL NIVE: ELSE ::', pcode, nvparte   ); commit;

     ----dbms_output.put_line( 'entes del insert');

     begin
      INSERT INTO partep2(CODE, Partep_DESC,PIDM)
        select  datos.codigo , datos.Partep_DESC , PPIDM
        from (
        SELECT DISTINCT SO.SOBPTRM_PTRM_CODE codigo,
            --to_number( substr(SO.SOBPTRM_PTRM_CODE,2,2))  mes,
             to_char(SOBPTRM_START_DATE, 'DD/MM/YYYY')||'-AL-'||to_char(SOBPTRM_END_DATE, 'DD/MM/YYYY') as Partep_DESC
          -- , ;pidm pidm
             ,sobptrm_start_date
             ,sobptrm_end_date
              ,SO.SOBPTRM_TERM_CODE term
             FROM stvterm, sobptrm  SO ---, spriden
               WHERE     SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                     AND LENGTH (SOBPTRM_PTRM_CODE) = 3
                   --  AND   ( trunc(sysdate)+1  BETWEEN TRUNC (sobptrm_start_date)   AND TRUNC (sobptrm_end_date)  --SE QUITO TODO SE VA AL NEXT LUNES 19/04/021 GLOVICX
                   --         OR (TRUNC (sobptrm_start_date) > trunc(sysdate)  ) )
                       AND   TRUNC (sobptrm_start_date) >= trunc(sysdate)  ---ESTA LINEA SE AGREGO POR EL NUEVO CAMBIO TODO SE VA A LUNES GLOVICX 1904021
                     AND sobptrm_term_code = stvterm_code
                     and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                     -- and substr(sobptrm_term_code,5,2) in (''||nvparte )
                     and substr(SOBPTRM_DESC,1,3) = (select distinct decode(SFRSTCR_LEVL_CODE,'MS', 'MAS','MA','MAE','LI','LIC', 'BA','BAC' )
                                                                          from sfrstcr  rr
                                                                          where SFRSTCR_PIDM = Ppidm
                                                                          and SFRSTCR_TERM_CODE = (select max(SFRSTCR_TERM_CODE)
                                                                                                   from sfrstcr cc
                                                                                                    where cc.SFRSTCR_PIDM = rr.SFRSTCR_PIDM)   )

                        order by sobptrm_start_date
                     )  datos
        where 1=1
        and rownum <= 10
         ;
    exception when others then
        null;
       --dbms_output.put_line( 'entes del insert'||  sqlerrm);

    end;


    END IF;


 COMMIT;

    VSALIDA   := 'EXITO';
   RETURN   VSALIDA;

Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error :'||sqlerrm;
       --insert into twpasow(valor1, valor2, valor3, valor4)
               --   values('error fechas parte de periodo gral', NULL , VFINI, VSALIDA   );
                --  commit;

    RETURN (VSALIDA);

END F_PTE_PERIODO;



FUNCTION F_MAIL (PPIDM NUMBER, PCODE  VARCHAR2 ) Return VARCHAR2  IS


 CONTADOR  NUMBER;
 VSALIDA   varchar2(300);

-- SE HIZO UN AJUSTE PARA NIVELACIONES  INGLES  glovicx 25/10.022

BEGIN


IF PCODE = 'NIVG' then  -- nivelacion ingles
SELECT COUNT (*)
        INTO contador
        FROM svrsrad
       WHERE  svrsrad_srvc_code = PCODE
         AND   UPPER(svrsrad_addl_data_title) LIKE '%EMAIL%';



else
      SELECT COUNT (*)
        INTO contador
        FROM svrsrad
       WHERE     svrsrad_srvc_code = PCODE
             AND   UPPER(svrsrad_addl_data_title) LIKE '%CORREO%';


end if; -- fin ingles

      IF contador > 0
      THEN
         DELETE FROM GZREMAL2
               WHERE z_pidm = Ppidm;

         INSERT INTO gzremal2
            SELECT GOREMAL_EMAIL_ADDRESS EMAL_CODE,
                   GOREMAL_EMAIL_ADDRESS EMAIL_ADRRES,
                   GOREMAL_PIDM
              FROM GOREMAL
             WHERE     GOREMAL_PIDM = pPidm
                   AND GOREMAL_EMAL_CODE IN
                          ('PRIN', 'REFE', 'ALTE', 'INST', 'LABO');

         COMMIT;
      END IF;

  VSALIDA   := 'EXITO';
 RETURN   VSALIDA;

Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error :'||sqlerrm;

    RETURN (VSALIDA);

END F_MAIL;

FUNCTION F_TCARTERA  (PPIDM NUMBER, LTERM  VARCHAR2, PCODE VARCHAR2,PMONTO  NUMBER,PNO_SERV  NUMBER,  p_delivery_type VARCHAR2 , PPROGRAMA varchar2,feed varchar2 default null ) RETURN varchar2
IS
--------IGUAL A LA VERSION ANONIMO 09/04/2021
--se agrega la funcionalidad de unicef glovicx 17/01/2022
-- SE AGREGA FUNCIONALIDAD NUEVAS CERTIFICACIONES Y MEX GRATIS 13.09.022

VSALIDA            VARCHAR2(900):='EXITO';
lv_trans_number    NUMBER:=0;
p_protocol_seq_no  NUMBER:=0;
VCODE_DTL          VARCHAR2(10);
VDESC_DTL          VARCHAR2(100);
vigencia           NUMBER:=0;
dias               NUMBER:=0;
vcode_envio        varchar2(5);
vimporte_envio     number;
vvueltas           number;
vmonto             number;
vstst               varchar2(10);
vlevel              varchar2(10);
vcamp               varchar2(10);
vcodigo_dtl     varchar2(5);
pregreso        varchar2(1000):='EXITO';
vperiodo        varchar2(12);
VNO_DOCTO       VARCHAR2(30);
Vpparte          varchar2(5);
vmatricula       varchar2(14);
Vstudy           number:=0;
f_inicio         varchar2(14);
f_fin            varchar2(14);
VSALIDA_MAIL     VARCHAR2(500);
vsalida2        number:=0;
vcode_curr      VARCHAR2(32767);
VACC            VARCHAR2(4);
VCAMPEXP        VARCHAR2(4);
VMESES          NUMBER:=0;
vsal_dif        varchar2(150);
vsal_notran     VARCHAR2(30);
VPROGRAMA       VARCHAR2(32767);
VEXIST_CERO     NUMBER:=0;
Vcursera        varchar2(1):='N';
VCODE_DTLX      varchar2(4);
vsal_cursera    varchar2(40):='EXITO';
P_ADID_CODE   VARCHAR2(5):= 'COUR';
P_ADID_ID     VARCHAR2(5):= 'COUR';
vetiqueta     varchar2(50);
v_valida_f_cour   varchar2(30);
VFECHA_INI       varchar2(20);
vfeed            varchar2(30);
vcampus          varchar2(4);
VDESC2           number:=0;
vgratis          VARCHAR2(50);
vtran_pay        number:=0;
vaccesorio       VARCHAR2(250);

/*
 PPIDM NUMBER;
  LTERM VARCHAR2(32767);
  PCODE VARCHAR2(32767);
  PMONTO NUMBER;
  PNO_SERV NUMBER;
  P_DELIVERY_TYPE VARCHAR2(32767);
  VPROGRAMA VARCHAR2(32767);
*/

BEGIN


execute immediate  'ALTER SESSION SET NLS_DATE_FORMAT = ''DD/MM/YYYY''';


/*-
 PPIDM := 764;
  LTERM := '012181';
  PCODE := 'COLF';
  PMONTO := 15000;
  PNO_SERV := 53404;
  P_DELIVERY_TYPE := '01UF';
  VPROGRAMA := 'UTLLIAAFED';
*/
--se puso para el colf xnivel
VPROGRAMA := PPROGRAMA;


        begin
        select SGBSTDN_STST_CODE, SGBSTDN_LEVL_CODE, SGBSTDN_CAMP_CODE
          into  vstst, vlevel, vcamp
        from sgbstdn  c
        where C.sgbstdn_PIDM  = PPIDM
        and  c.SGBSTDN_TERM_CODE_EFF = ( select max(SGBSTDN_TERM_CODE_EFF) from sgbstdn cc
                                            where Cc.sgbstdn_PIDM  = c.sgbstdn_PIDM
                                             and  CC.SGBSTDN_PROGRAM_1  = VPROGRAMA
                                         )  ;
        exception when others then
        null;

            ----dbms_output.put_line( 'ERRORR:::SALIDA GASTON ;'||vstst||'-'||vlevel||'-'|| vcamp );
        end;

       begin

               select ZSTPARA_PARAM_VALOR
                  INTO vcode_curr
                from zstpara
                where ZSTPARA_MAPA_ID = 'CAMPUS_AUTOSERV'
                AND ZSTPARA_PARAM_ID = vcamp; ---ESTE ES EL CAMPUS

        EXCEPTION WHEN OTHERS THEN
           vcode_curr:='Error :'||sqlerrm;
           -- vigencia := 0;
            VSALIDA:='Error en codigo de moneda :'||sqlerrm;
        END;




---lo primero que vamos a validar es si el campues esta en el parametrizador de los accesorios que tienen cargo diferido
       BEGIN


        select DISTINCT ZSTPARA_PARAM_ID, ZSTPARA_PARAM_VALOR
            INTO  VACC, VCAMPEXP
        from zstpara
        where 1=1
        and ZSTPARA_MAPA_ID   = 'TITULA_DIFERIDA'
        AND  ZSTPARA_PARAM_VALOR   = vcamp
        AND ZSTPARA_PARAM_ID  = PCODE;

       EXCEPTION WHEN OTHERS THEN
        VACC := NULL;
        VCAMPEXP := NULL;

       END;

       ----primero validamos los meses para ver si entra al proceso de REZA o al mio
        BEGIN    -----------------recupera la parte de periodo que solicito el alumno
           select DISTINCT SUBSTR(SVRSVAD_ADDL_DATA_CDE,1,decode(INSTR(SVRSVAD_ADDL_DATA_CDE,' ',1),0,10, INSTR(SVRSVAD_ADDL_DATA_CDE,' ',1))-1)
               INTO VMESES
                from svrsvpr v,SVRSVAD VA
                where SVRSVPR_SRVC_CODE = PCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                  AND  SVRSVPR_PIDM    = PPIDM
                   and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                   and va.SVRSVAD_ADDL_DATA_SEQ = '5' ---ESTE SIEMPRE VA ES EL VALOR DE NUMERO DE MESES A DIFERIR
          ;
          EXCEPTION WHEN OTHERS THEN
            VMESES:=0;

          END;

        BEGIN
           select SVRSVPR_RSRV_SEQ_NO
           INTO p_protocol_seq_no
            from svrsvpr
            where SVRSVPR_SRVC_CODE = PCODE   ---CODIGO DE SERV
            AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV  ---NO DE SERVICIO
              AND  SVRSVPR_PIDM    = PPIDM
            ;
        EXCEPTION WHEN OTHERS THEN
            VSALIDA:='Error :'||sqlerrm;
          p_protocol_seq_no := 0;

       END;
        ----dbms_output.PUT_LINE('NO SEQ. DE PROTOCOLO:: '||p_protocol_seq_no );


       begin
         select F_GetSpridenID(PPIDM)
            into vmatricula
            from dual;

        EXCEPTION WHEN OTHERS THEN
            VSALIDA:='Error :'||sqlerrm;
          vmatricula := '0';

       END;



       BEGIN
         SELECT  DISTINCT SVRRSSO_DETL_CODE,SVRRSSO_WSSO_CODE
          INTO    VCODE_DTL,vcode_envio
           FROM SVRRSSO o, SVRRSRV r
            WHERE  1=1
            AND o.SVRRSSO_SRVC_CODE     = R.SVRRSRV_SRVC_CODE
            and O.SVRRSSO_RSRV_SEQ_NO = R.SVRRSRV_SEQ_NO
            AND SVRRSSO_SRVC_CODE = PCODE--protocol_code_in  CDIGO DE SERVICIO
            AND SVRRSSO_WSSO_CODE = p_delivery_type ---CODIGO DE ENVIO
            and substr(SVRRSSO_DETL_CODE,1,2)  = substr(vmatricula,1,2) ---- esto es para saber de que campues es el alumno
            and r.SVRRSRV_LEVL_CODE  = vlevel --NIVEL  ---ESTA MODIFICACION SE HIZO PARA TOMAR EL CODIGO CORRECTO POR NIVEL Y QUE DEJE HACER UNA COLF DE CADA NIVEL GLOVICX 25/05/2021
            and r.SVRRSRV_STST_CODE   =  vstst  --status del alumn
            and r.SVRRSRV_CAMP_CODE   =  vcamp ;  -- campus



        EXCEPTION WHEN OTHERS THEN
          VSALIDA:='Error :'||sqlerrm;
         --   VCODE_DTL:='';
         ----dbms_output.PUT_LINE('detalle code1 :: '||VSALIDA );
             BEGIN
              select DISTINCT SVRRSSO_DETL_CODE,SVRRSSO_WSSO_CODE
                 INTO    VCODE_DTL,vcode_envio
                   FROM SVRRSSO
                    WHERE  1=1
                        -- AND SVRRSSO_RSRV_SEQ_NO   = p_protocol_seq_no
                         AND SVRRSSO_SRVC_CODE = PCODE--protocol_code_in  CDIGO DE SERVICIO
                         AND SVRRSSO_WSSO_CODE = p_delivery_type ---CODIGO DE ENVIO
                           and substr(SVRRSSO_DETL_CODE,1,2)  = substr(vmatricula,1,2) ---- esto es para saber de que campues es el alumno
                        ;
             EXCEPTION WHEN OTHERS THEN
                VSALIDA:='Error :'||sqlerrm;
                 VCODE_DTL:='';

              END;
       END;

     --
        BEGIN
          SELECT DISTINCT TBBDETC_DESC
           INTO    VDESC_DTL
           FROM TBBDETC
           WHERE TBBDETC_DETAIL_CODE = VCODE_DTL;
         EXCEPTION WHEN OTHERS THEN
                VSALIDA:='Error :'||sqlerrm;
                 VDESC_DTL:='';

         END;
              ---- optenemos study se puso aqui para el colf x nivel
           Begin

             select distinct max(tz.sp)
            into Vstudy
            from tztprog tz
            where 1=1
            and tz.pidm = PPIDM
            and TZ.PROGRAMA  = VPROGRAMA
            and tz.sp         = ( select max( tt.sp)  from tztprog tt
                                             where 1=1
                                               and  tz.matricula = tt.matricula
                                               and TZ.PROGRAMA  =  Tt.PROGRAMA);

            Exception
            when Others then
            Vstudy := null;
            VSALIDA  := 'Se presento un error al obtener la informacion de SORLCUR-key_seq_no ' ||PPIDM||'-'||  VPROGRAMA|| sqlerrm;
            End;


--       insert into twpasow ( valor1, valor2, valor3, valor4)
--       values ('COLF_dif_ calcula VSTUDY:1',PPIDM, PNO_SERV, Vstudy );
--       commit;

    -----------------------  aqui vamos a mandar los cursos CESA FLUJO UNICO TIENE SU PROPIA FUNCION glovicx 12/04/021
    IF PCODE in ( 'CELI','CEMA','CEMM' )    then
    --
    --CELI- CESA Licenciatura
    --CEMA- CESA Maestría
    --CEMM- CESA Master
    null;

      VSALIDA := BANINST1.PKG_SERV_SIU.F_CESA (PPIDM ,VCODE_DTL ,VPROGRAMA, PNO_SERV,PCODE );


     --VSALIDA :=  substr(vsal_dif, 1,instr(vsal_dif,'|',1)-1);


      IF VSALIDA = 'EXITO' THEN

       ----dbms_output.PUT_LINE('TERMINA FLUJO 1CESA :: '||  VSALIDA);

        commit;

        RETURN  (VSALIDA);

       else


        rollback;
        RETURN  substr(VSALIDA,1,300);
      end if;

    end if;

-----SE EJECUTA--FLUJO UNICO TIENE SU PROPIA FUNCION  GLOVICX ESTO ES PROYECTO DE <<COLF>> CARGOS DIFERIDOS 22/02/021
 IF   VACC = PCODE  AND  VCAMPEXP = vcamp  and VMESES > 1  THEN

         ----dbms_output.put_line(' INICIA COLF DIFERIDA calcula meses Y CODIGO DE DETALLE:  '||PPIDM||'-'||VCODE_DTL||'--'||VMESES||'-'||VPROGRAMA||'-'||PNO_SERV);
      VSALIDA  := BANINST1.PKG_SERV_SIU.F_COLF_DIFF ( PPIDM , VCODE_DTL , VMESES ,VPROGRAMA ,PNO_SERV  , PCODE ,p_delivery_type ,
                       LTERM ,  f_inicio , Vstudy , Vpparte , vcode_curr  ,vstst ,vcamp ,vlevel   ) ;

   ----dbms_output.PUT_LINE('TERMINA FLUJO COLF DIFF 1:: '||  VSALIDA);
    RETURN  (VSALIDA);

   --RETURN  ('EXITO');

 -------------------hast aaqui termina este flujo-------

 ELSE
    --NO CUMPLE LA PRIMERA PARTE ENTONCES ES EL FLUJO NORMAL PARA TODOS.  SE QUITO ESTA PARTE PARA HACERLA NUEVA FUNCION F_COSTO_ENVIO GLOVICX--08/04/021
 vimporte_envio :=  BANINST1.PKG_SERV_SIU.F_COSTO_ENVIO ( UPPER(PCODE),vstst,vcamp,vlevel, p_delivery_type   );




         BEGIN
              SELECT MAX (szrrcon_vig_pag)
                 INTO vigencia
                   FROM szrrcon
                   WHERE szrrcon_srvc_code = PCODE;--protocol_code_in  CDIGO DE SERVICIO

         EXCEPTION WHEN OTHERS THEN
           VSALIDA:='Error :'||sqlerrm;
            vigencia := 0;

        END;



        ----dbms_output.PUT_LINE('NO DE VIGENCIA ' || vigencia );

                     IF vigencia IS NULL OR vigencia = 0
                     THEN
                        dias := 3;
                     ELSE
                        dias := vigencia;
                     END IF;


 if vimporte_envio > 0 then
  vvueltas := 2;
        ----dbms_output.PUT_LINE('NO DE VUELTAS 2---' || vimporte_envio );
  else
  vvueltas := 1;
     ----dbms_output.PUT_LINE('NO DE VUELTAS 1--' || vimporte_envio );

 end if;

 for j in 1..vvueltas loop

    if j = 1 then
     BEGIN
          SELECT DISTINCT TBBDETC_DESC
           INTO    VDESC_DTL
           FROM TBBDETC
           WHERE TBBDETC_DETAIL_CODE = VCODE_DTL;
       ----dbms_output.PUT_LINE('NO DE DESCRPCION_1: ' || VDESC_DTL||'-'|| VCODE_DTL );

         vcodigo_dtl := VCODE_DTL;

       ----dbms_output.PUT_LINE('NO DE TRANSACCION ' || lv_trans_number );


      EXCEPTION WHEN OTHERS THEN
            VSALIDA:='Error :'||sqlerrm;
            ----dbms_output.PUT_LINE('NO DE TRANSACCION ' || lv_trans_number );

        END;

       vmonto := PMONTO;

      ----dbms_output.PUT_LINE('DESCRIPCION DE DETALLE1 en j '||j ||  VDESC_DTL );

       BEGIN
        SELECT NVL (MAX (tzraccd_tran_number), 0) + 1
               INTO lv_trans_number
               FROM tzraccd
              WHERE tzraccd_pidm = PPIDM;
       EXCEPTION WHEN OTHERS THEN
           --VSALIDA:='Error :'||sqlerrm;
            lv_trans_number := 0;

       END;

       ----dbms_output.PUT_LINE('NO DE TRANSACCION ' || lv_trans_number );




    ELSE

        BEGIN
          SELECT DISTINCT TBBDETC_DESC
           INTO    VDESC_DTL
           FROM TBBDETC
           WHERE TBBDETC_DETAIL_CODE = p_delivery_type;
           ----dbms_output.PUT_LINE('NO DE DESCRPCION_2 ' || VDESC_DTL||'-'||vcode_envio );
         ----dbms_output.PUT_LINE('DESCRIPCION DE DETALLE2 en j '||j ||  VDESC_DTL );

         vcodigo_dtl := p_delivery_type;


        EXCEPTION WHEN OTHERS THEN
              --VSALIDA:='Error :'||sqlerrm;
              null;
        END;

       vmonto := vimporte_envio ;

      end if;

       IF PCODE in ( 'NIVE' , 'NIVG' ) THEN

       BEGIN

          select  DISTINCT  va.SVRSVAD_ADDL_DATA_CDE
           INTO VNO_DOCTO
            from svrsvpr v,SVRSVAD VA
            where SVRSVPR_SRVC_CODE = PCODE
            AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
              AND  SVRSVPR_PIDM    = PPIDM
               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
               and va.SVRSVAD_ADDL_DATA_SEQ = '2' ---ESTE SIEMPRE VA ES AL VALOR DE LA MATERIA EN NIVELACION
      ;
      EXCEPTION WHEN OTHERS THEN
        VNO_DOCTO:='';

      END;

          BEGIN    -----------------recupera la parte de periodo que solicito el alumno
           select SVRSVAD_ADDL_DATA_CDE , SVRSVPR_CAMP_CODE--DISTINCT SUBSTR(SVRSVAD_ADDL_DATA_CDE,1,decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1))-1)
                  , substr(SVRSVAD_ADDL_DATA_DESC,1, instr(SVRSVAD_ADDL_DATA_DESC,'-',1)-1 ) fecha_ini
               INTO Vpparte, vcampus,  f_inicio
                from svrsvpr v,SVRSVAD VA
                where SVRSVPR_SRVC_CODE = PCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                  AND  SVRSVPR_PIDM    = PPIDM
                   and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                   and va.SVRSVAD_ADDL_DATA_SEQ = '7' ---ESTE SIEMPRE VA ES AL VALOR DE LA MATERIA EN NIVELACION
          ;
          EXCEPTION WHEN OTHERS THEN
            Vpparte:='';
             vcampus :='';  
             f_inicio :='';
          
          END;

            

          ---aqui calcula el nuevo codigo de detalle para las nivealciones este es el proeycto y reglas de tavo
          --  en base a la nuevas reglas SZFNIPR  costo por %  glovicx 27/04/022
              BEGIN
                   SELECT ROUND(nvl(SZTHITA_AVANCE,0))
                      INTO VDESC2
                        FROM SZTHITA ZT
                        WHERE ZT.SZTHITA_PIDM = PPIDM
                        AND    ZT.SZTHITA_LEVL  = substr(VPROGRAMA,4,2)
                        AND   ZT.SZTHITA_PROG   = VPROGRAMA  ;
                        ----dbms_output.PUT_LINE('SALIDA AVANCE HITA  '|| VDESC2);
               EXCEPTION WHEN OTHERS THEN
                VDESC2 :=0;
                        BEGIN
                           SELECT ROUND(BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 ( PPIDM, vPROGRAMA ))
                                  INTO VDESC2
                             FROM DUAL;

                          --   --dbms_output.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
                          EXCEPTION WHEN OTHERS THEN
                           VDESC2 :=0;
                          END;
              END;
              
              
               
       ---- aqui hay 2 formas con costo cero o costo normal
         -- NUEVA REGLA se inserta en cartera un reg de condonación x $$ y al final si pasa la materia se cancela si no pasa entonces tiene que pagarla
         --  glovicx 13.08.2024
          --dbms_output.PUT_LINE('ANTES DE MONTO CERO  '|| PMONTO ||'-'||PPIDM||'-'||VLEVEL||'-'||VPROGRAMA);
           -------------------OBTIENE EL nombre ------------
              BEGIN
                    ---se cambia la forma de calcular el costo del cargo temporal costocerov2, glovicx 16.08.2024

                select distinct SZT_CODE, SZT_DESCRIPCION, SZT_PRECIO
                  INTO  vcodigo_dtl ,VDESC_DTL,  vmonto
                    from sztnipr
                    where 1=1
                    and SZT_NIVEL =  substr(VPROGRAMA,4,2)
                    and SZT_CAMPUS  =  vcampus
                    and SZT_PRECIO  > 0
                    and ROUND(VDESC2) between ( SZT_MINIMO ) and (SZT_MAXIMO )
                    and substr(SZT_CODE,1,2) = substr(F_GetSpridenID(PPIDM),1,2);


                        ----dbms_output.PUT_LINE('SALIDA COSTOS_PARAMETROS  '|| VDESC ||'-'|| VCOSTO);
              EXCEPTION WHEN OTHERS THEN
                vsalida := sqlerrm;
                VDESC_DTL := '';  
                vmonto := 0;
                vcodigo_dtl:= null;
              
              END;





       ELSE
        VNO_DOCTO := lv_trans_number;


      END IF;


     ------------------------aqui saco los datos para TISU Y EXTRA  de campus UNICA-- glovicx 23/1120
       IF PCODE IN ('EXTR') THEN

       BEGIN
       select  distinct SVRSVAD_ADDL_DATA_CDE
           --DISTINCT SUBSTR(SVRSVAD_ADDL_DATA_CDE,1,decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1))-1)
           INTO VNO_DOCTO
            from svrsvpr v,SVRSVAD VA
            where SVRSVPR_SRVC_CODE = PCODE
            AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
              AND  SVRSVPR_PIDM    = PPIDM
               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
               and va.SVRSVAD_ADDL_DATA_SEQ = '2' ---ESTE SIEMPRE VA ES AL VALOR DE LA MATERIA EN NIVELACION
      ;
      EXCEPTION WHEN OTHERS THEN
        VNO_DOCTO:='';

      END;

          BEGIN    -----------------recupera la parte de periodo que solicito el alumno
           select DISTINCT SUBSTR(SVRSVAD_ADDL_DATA_CDE,1,decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1))-1)
               INTO Vpparte
                from svrsvpr v,SVRSVAD VA
                where SVRSVPR_SRVC_CODE = PCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                  AND  SVRSVPR_PIDM    = PPIDM
                   and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                   and va.SVRSVAD_ADDL_DATA_SEQ = '7' ---ESTE SIEMPRE VA ES AL VALOR DE LA MATERIA EN NIVELACION
          ;
          EXCEPTION WHEN OTHERS THEN
            Vpparte:='';

          END;

              Begin

                   -- select distinct sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
                   select distinct TO_CHAR(sobptrm_start_date, 'DD/MM/YYYY') , TO_CHAR(sobptrm_end_date, 'DD/MM/YYYY')
                    into f_inicio, f_fin
                    from sobptrm
                    where sobptrm_term_code  =LTERM
                    and     sobptrm_ptrm_code=VPparte
                    and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                    and substr(sobptrm_term_code,5,2) in (81,82,83)


                    ;
                Exception
                 When Others then
                    f_inicio  := '';
                   -- vl_error := 'No se Encontro fecha ini/ffin para el Periodo= ' ||LTERM ||' y Parte de Periodo= '||VPparte ||sqlerrm;
                  --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('INSRT_HORARIO_FECHAS_ERROORR22:: ',Ppidm, PSEQ_NO,Pperiodo||'-'||VPparte, SUBSTR(vl_error,1,200), sysdate);
                  VSALIDA  := SQLERRM;
               End;

      ELSIF   PCODE IN ('TISU') THEN



      BEGIN
       select  distinct SVRSVAD_ADDL_DATA_CDE
           --DISTINCT SUBSTR(SVRSVAD_ADDL_DATA_CDE,1,decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1))-1)
           INTO VNO_DOCTO
            from svrsvpr v,SVRSVAD VA
            where SVRSVPR_SRVC_CODE = PCODE
            AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
              AND  SVRSVPR_PIDM    = PPIDM
               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
               and va.SVRSVAD_ADDL_DATA_SEQ = '2' ---ESTE SIEMPRE VA ES AL VALOR DE LA MATERIA EN NIVELACION
      ;
      EXCEPTION WHEN OTHERS THEN
        VNO_DOCTO:='';

      END;

          BEGIN    -----------------recupera la parte de periodo que solicito el alumno
           select SVRSVAD_ADDL_DATA_CDE --DISTINCT SUBSTR(SVRSVAD_ADDL_DATA_CDE,1,decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1))-1)
               INTO Vpparte
                from svrsvpr v,SVRSVAD VA
                where SVRSVPR_SRVC_CODE = PCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                  AND  SVRSVPR_PIDM    = PPIDM
                   and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                   and va.SVRSVAD_ADDL_DATA_SEQ = '7' ---ESTE SIEMPRE VA ES AL VALOR DE LA MATERIA EN NIVELACION
          ;
          EXCEPTION WHEN OTHERS THEN
            Vpparte:='';

          END;

              Begin

                   -- select distinct sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
                   select distinct TO_CHAR(sobptrm_start_date, 'DD/MM/YYYY') , TO_CHAR(sobptrm_end_date, 'DD/MM/YYYY')
                    into f_inicio, f_fin
                    from sobptrm
                    where sobptrm_term_code  =LTERM
                    and     sobptrm_ptrm_code=VPparte
                    and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                    and substr(sobptrm_term_code,5,2) in (84,85,86)


                    ;
                Exception
                 When Others then
                    f_inicio  := '';
                   -- vl_error := 'No se Encontro fecha ini/ffin para el Periodo= ' ||LTERM ||' y Parte de Periodo= '||VPparte ||sqlerrm;
                  --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('INSRT_HORARIO_FECHAS_ERROORR22:: ',Ppidm, PSEQ_NO,Pperiodo||'-'||VPparte, SUBSTR(vl_error,1,200), sysdate);
                  VSALIDA  := SQLERRM;
               End;



       ELSE
        VNO_DOCTO := lv_trans_number;


      END IF;



       ----dbms_output.put_line('numero de pasadas j:: '|| j);
       ---- optenemos study
            Begin

             select distinct max(tz.sp)
            into Vstudy
            from tztprog tz
            where 1=1
            and tz.pidm = PPIDM
            and TZ.PROGRAMA  = VPROGRAMA
            and tz.sp         = ( select max( tt.sp)  from tztprog tt
                                             where 1=1
                                               and  tz.matricula = tt.matricula
                                               and TZ.PROGRAMA  =  Tt.PROGRAMA);

            Exception
            when Others then
            Vstudy := null;
            VSALIDA  := 'Se presento un error al obtener la informacion de SORLCUR-key_seq_no ' ||PPIDM||'-'||  VPROGRAMA|| sqlerrm;
            End;

       -----------NUEVA VALIDACION PARA QUE NO SE INSERTE NADA QUE YA EXISTA EN TBRACCD  GLOVICX 04/02/2020
--         insert into twpasow(valor1, valor2, valor3)
--             values('validacion extra TRABCCD_222',PPIDM,VCODE_DTL  );
      IF pcode = 'COLF' THEN
          begin

            for jump in (
            select *
            from tbraccd T
            where T.tbraccd_pidm= PPIDM
            AND  T.TBRACCD_DETAIL_CODE  = VCODE_DTL  ---CON ESTA SECCION LIMITA A QUE SE PUEDA METER UN CODIGO X NIVEL, SOLO PUEDE TENER UNA COLF POR NIVEL
            and t.TBRACCD_DOCUMENT_NUMBER != 'WCANCE'  --busca todos los codigos de detalle que no esten cancelados por el sistema
            and t.TBRACCD_CROSSREF_NUMBER <> PNO_SERV
            and TBRACCD_STSP_KEY_SEQUENCE  = Vstudy
            order by 2 desc

             ) loop
             ----dbms_output.put_line('validacion extra en tbraccd ANIDADO DE PAGO:  ' || JUMP.tbraccd_pidm);
            ---------si regresa algun registro tenemos que validar si esta pagado o cancelada para dejar o no seguir con el nuevo
--             insert into twpasow(valor1, valor2, valor3)
--             values('validacion extra TRABCCD',PPIDM,VCODE_DTL  );
            --1ro validamos que no este activo eso es con sl amount = balance  si cualquiera de los siguientes
            ----- regresa mayor a cero entonces hay pago o esta activo algo asi y no debe insertar nada

             if jump.TBRACCD_AMOUNT = jump.TBRACCD_BALANCE then
               vsalida  := 'Servicio activo';
               vsalida2  := 1;
                  -- --dbms_output.put_line('validacion OPCION 1 extra en tbraccd');
              elsif jump.TBRACCD_BALANCE > 0 then
                  vsalida  := 'Tiene pago parcial';
                  vsalida2  := 1;
                --  --dbms_output.put_line('validacion OPCION 2 extra en tbraccd');

                else

                 select COUNT(1)
                         INTO  vsalida2
                                from (
                                    select *    ------SI REGRESA EL VALOR DE MAYOR A UNO YA ESTA PAGADO
                                    from tbrappl ppl
                                    where tbrappl_pidm = jump.tbraccd_pidm
                                      and PPL.TBRAPPL_CHG_TRAN_NUMBER  = jump.TBRACCD_TRAN_NUMBER  ---NO de transaccion del servicio
                                      and ppl.TBRAPPL_DATA_ORIGIN != 'AD'
                                      union
                                    select *    ------SI REGRESA EL VALOR DE MAYOR A UNO YA ESTA PAGADO
                                    from tbrappl ppl
                                    where tbrappl_pidm = jump.tbraccd_pidm
                                      and PPL.TBRAPPL_CHG_TRAN_NUMBER  = jump.TBRACCD_TRAN_NUMBER  ---NO de transaccion del servicio
                                      and ppl.TBRAPPL_DATA_ORIGIN is  null
                                      );
                                 ----dbms_output.put_line('validacion OPCION 3 extra en tbraccd:  '|| vsalida2);

              end if;
            end loop;

             Exception
            when Others then
              vsalida2  := 0;

              --VSALIDA  := 'Se presento un error al obtener la informacion de SORLCUR-key_seq_no ' ||PPIDM||'-'||  VPROGRAMA|| sqlerrm;
            end;

        else
         vsalida2  := 0;
      end if;
         ----dbms_output.PUT_LINE('FIN LOOP DE PAGO VSALIDA2::: ' || vsalida2 ||'->>>'||vsalida );
  IF J = 1 then --quiere decir que esta en la segunda vuelta tiene envio internacional --costo cero glovicx 22/09/021
        begin
            select count(1)
                 into vsalida2
              from SVRSVPR
              WHERE 1=1
                and   SVRSVPR_PIDM = PPIDM
                and   SVRSVPR_PROTOCOL_SEQ_NO  = PNO_SERV
                and   SVRSVPR_SRVC_CODE  IN  ( select ZSTPARA_PARAM_DESC
                                                  from zstpara
                                                    where 1=1
                                                     and zstpara_mapa_id = 'code_cero')
                and   SVRSVPR_PROTOCOL_AMOUNT = 0;


        exception when others then
          vsalida2 := 0;
        end;
   end if;
          ----dbms_output.PUT_LINE('salida costo cero VSALIDA2::: ' || vsalida2 ||'-no vuelta--'||  j );


        --HACE LA VALIDACION CURSERA--solo si cumple la función SE MANDA PARA QUE ACTUALIZA EL ESTATUS
        -- EJECUTE LA FUNCION DE CHUY
        -- INSERTE LA ETIQUETA GORADID

   /*    SE DESACTIVA ESTA FUNCIONALIDAD YA NO VA POR ESTE FLUJO CAMBIO FLUJO GRAL CERTIFICACIONES GLOVICX 02/05/022
        IF Vcursera = 'Y' AND VMESES != 1 THEN
            vsalida2 := 1; -- NO ENTRA A TBRACCD POR QUE SI MANDO mas de 1 mes  LA INSERTA REZA





         END IF;

        IF Vcursera = 'Y' AND VMESES = 1 THEN
        vsalida2 := 0;
         --HACE LA VALIDACION CURSERA--solo si cumple la función SE MANDA PARA QUE ACTUALIZA EL ESTATUS
        -- EJECUTE LA FUNCION DE CHUY
        -- INSERTE LA ETIQUETA GORADID
         vsal_cursera :=   F_CURSERA ( PPIDM ,PCODE, VCODE_DTLX,VMESES,PNO_SERV ,VMESES );
         --PERO SIGUE EL FLUJO NORMAL DE INSERTAR EL CARGO EN TBRACCD
        vcodigo_dtl  := VCODE_DTLX;
       end if;

   */

        --AQUI BUSCAMOS EL CODIGO DE DETALLE DEL SERVICIO QUE COMPRO EL ALUMNO PARA CONECTA GLOVICX 002/03/022
        --SE AGREO LOS CODIGOS DE UNICEF PARA CALCULAR EL CODE DTL GLOVICX 28/03/022
      IF PCODE  IN ('CNLI','CNMA','CNMM', 'CNDO', 'UNLI','UNMA','UNMM')  THEN
      
            BEGIN
                select  va.SVRSVAD_ADDL_DATA_CDE code_dtl
                       ----  ,substr(VA.SVRSVAD_ADDL_DATA_DESC, 1, instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)-1) meses
                      ----    ,V.SVRSVPR_ACCD_TRAN_NUMBER  numtran   
                              into VCODE_DTLX    ---,VMESES,vtran_pay     se quitaron opcione x que no se usan glovicx 02.08.2023
                                from svrsvpr v,SVRSVAD VA
                                where 1=1
                                   AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                                   AND  SVRSVPR_PIDM   = PPIDM
                                   and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                  and va.SVRSVAD_ADDL_DATA_SEQ = '5' ---- codigo de detalle para saber los meses

                                ;

            EXCEPTION WHEN OTHERS THEN
            VCODE_DTLX  := '';
            VMESES      := '';
            vtran_pay   := 0;
            --dbms_output.PUT_LINE('ERROR EN CODE DE DETALLE1  '||PNO_SERV ||'-'||   PPIDM ||'-'|| SQLERRM );
            END;
          --INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3,VALOR4)
          -- VALUES ('F_TCARTERA_CONECTA ', PPIDM, PNO_SERV, VCODE_DTLX ); COMMIT;

           BEGIN
          SELECT DISTINCT TBBDETC_DESC
           INTO    VDESC_DTL
           FROM TBBDETC
           WHERE TBBDETC_DETAIL_CODE = VCODE_DTLX;
           ----dbms_output.PUT_LINE('NO DE DESCRPCION_2 ' || VDESC_DTL||'-'||vcode_envio );
         ----dbms_output.PUT_LINE('DESCRIPCION DE DETALLE2 en j '||j ||  VDESC_DTL );

        EXCEPTION WHEN OTHERS THEN
              --VSALIDA:='Error :'||sqlerrm;
              null;
        END;

           vcodigo_dtl  := VCODE_DTLX;

           ---hay que concatenar  para enviarlos en la nueva columna de FEED glovicx 05/04/022-
            IF PCODE  IN ( 'UNLI','UNMA','UNMM')  THEN
              vfeed := '1|'||VMESES;
             end if;

        END IF;

         IF PCODE  IN ('VOXY')  THEN
            BEGIN
                 select  SVRSVAD_ADDL_DATA_CDE code_dtl  --,substr(VA.SVRSVAD_ADDL_DATA_DESC, 1, instr(VA.SVRSVAD_ADDL_DATA_DESC,' ',1)-1) meses
                              into VCODE_DTLX   --,VMESES
                                from svrsvpr v,SVRSVAD VA
                                where 1=1
                                   AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                                   AND  SVRSVPR_PIDM   = PPIDM
                                   and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                  and va.SVRSVAD_ADDL_DATA_SEQ = '5' ---- codigo de detalle para saber los meses

                                ;

            EXCEPTION WHEN OTHERS THEN
            VCODE_DTLX  := '';
            VMESES      := '';
            --dbms_output.PUT_LINE('ERROR EN CODE DE DETALLE VOXY  '||PNO_SERV ||'-'||   PPIDM ||'-'|| SQLERRM );
            END;
          --INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3,VALOR4)
          -- VALUES ('F_TCARTERA_CONECTA ', PPIDM, PNO_SERV, VCODE_DTLX ); COMMIT;

         BEGIN
          SELECT DISTINCT TBBDETC_DESC
           INTO    VDESC_DTL
           FROM TBBDETC
           WHERE TBBDETC_DETAIL_CODE = VCODE_DTLX;
           ----dbms_output.PUT_LINE('NO DE DESCRPCION_2 ' || VDESC_DTL||'-'||vcode_envio );
         ----dbms_output.PUT_LINE('DESCRIPCION DE DETALLE2 en j '||j ||  VDESC_DTL );

        EXCEPTION WHEN OTHERS THEN
              --VSALIDA:='Error :'||sqlerrm;
              null;
        END;

           vcodigo_dtl  := VCODE_DTLX;

        END IF;


        IF PCODE  IN ( 'COLI','COMA','COMM')  THEN  ---SACA CODE_DTL COURSERA
             BEGIN
                 select  SVRSVAD_ADDL_DATA_CDE code_dtl  --,substr(VA.SVRSVAD_ADDL_DATA_DESC, 1, instr(VA.SVRSVAD_ADDL_DATA_DESC,' ',1)-1) meses
                              into VCODE_DTLX   --,VMESES
                                from svrsvpr v,SVRSVAD VA
                                where 1=1
                                   AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                                   AND  SVRSVPR_PIDM   = PPIDM
                                   and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                  and va.SVRSVAD_ADDL_DATA_SEQ = '5' ---- codigo de detalle para saber los meses

                                ;

            EXCEPTION WHEN OTHERS THEN
            VCODE_DTLX  := '';

            --dbms_output.PUT_LINE('ERROR EN CODE DE DETALLE COURSERA  '||PNO_SERV ||'-'||   PPIDM ||'-'|| SQLERRM );
            END;

               BEGIN
                  SELECT DISTINCT TBBDETC_DESC
                   INTO    VDESC_DTL
                   FROM TBBDETC
                   WHERE TBBDETC_DETAIL_CODE = VCODE_DTLX;
                   ----dbms_output.PUT_LINE('NO DE DESCRPCION_2 ' || VDESC_DTL||'-'||vcode_envio );
                 ----dbms_output.PUT_LINE('DESCRIPCION DE DETALLE2 en j '||j ||  VDESC_DTL );

                EXCEPTION WHEN OTHERS THEN
                      --VSALIDA:='Error :'||sqlerrm;
                      null;
                END;

                   vcodigo_dtl  := VCODE_DTLX;

        END IF;
       
      
      IF PCODE  = 'ENIN'  THEN  --- SEASIGA ESTA VALIDACIÓN PARA PRYECTO DE TIPOS DE ENVIO 20.12.2024
            
            BEGIN
                 select  SVRSVAD_ADDL_DATA_CDE code_dtl 
                      into VCODE_DTLX   
                        from svrsvpr v,SVRSVAD VA
                        where 1=1
                           AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                           AND  SVRSVPR_PIDM   = PPIDM
                           and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                           and va.SVRSVAD_ADDL_DATA_SEQ = '4' ---- codigo de detalle para saber los meses
                           ;

            EXCEPTION WHEN OTHERS THEN
            VCODE_DTLX  := '';
                      --dbms_output.PUT_LINE('ERROR EN CODE DE DETALLE VOXY  '||PNO_SERV ||'-'||   PPIDM ||'-'|| SQLERRM );
            END;
          
         BEGIN
          SELECT DISTINCT TBBDETC_DESC
           INTO    VDESC_DTL
           FROM TBBDETC
           WHERE TBBDETC_DETAIL_CODE = VCODE_DTLX;
          
        EXCEPTION WHEN OTHERS THEN
        VDESC_DTL := '';
         VSALIDA:='Error :'||sqlerrm;
          
        END;

           vcodigo_dtl  := VCODE_DTLX;

        END IF;

     

    IF vsalida2 = 0  then


     ----- aqui va la nueva funcion para ya unicamente hacver el insert a tbraccd  glovicx 08/04/021

     vsal_dif :=   BANINST1.PKG_SERV_SIU.F_INSERT_CARTERA (PCODE,PPIDM,LTERM,vcodigo_dtl,round(vmonto),VDESC_DTL,PNO_SERV,VNO_DOCTO, f_inicio,Vstudy,Vpparte,vcode_curr, vfeed , null);


      VSALIDA := substr(vsal_dif, 1,instr(vsal_dif,'|',1)-1);
      vsal_notran := substr( vsal_dif,instr(vsal_dif,'|',1)+1);
     --dbms_output.PUT_LINE('SALIDA INSERTA TBRACCD > 1 X:.  ' || VSALIDA );

            if j = 1  then  ---para cachar el num de tran del accesorio solamnete glovicx 14/07/021
               lv_trans_number := vsal_notran;

               --insert into twpasow(valor1, valor2, valor3, VALOR4, valor5, valor6, VALOR7)
              --values('DENTRO INSERTA TBRAA_NO_TRANSAC:'||j,ppidm,pno_serv, pcode, vsal_notran, lv_trans_number, SYSDATE  );
              --COMMIT;
             end if;

     else
     null;
       --VSALIDA:='Error :'||sqlerrm;  ----ya existe un servicio y esta activo

     ----dbms_output.PUT_LINE('SALIDA DIF SALIDA2 > 0 X:.  ' || VSALIDA );
     end if;  ---este fin de valida2 = 0
      ----dbms_output.PUT_LINE('antes del SENI 0 X:.  ' || PPIDM||'-'||Pcode||'-'||pno_serv );
      IF PCODE = 'SENI' THEN     -----glovicx 29.12.2022
        ------ ESTA certificación es codigo cero por lo tanto no hay aplicación de pagos
        ----- entonces lanzamos desde aqui la segunda parte del proceso que es la etiqueta y COTA
           VSALIDA :=  BANINST1.PKG_SERV_SIU.F_CURSO_SIU ( PPIDM ,Pcode , pno_serv   )   ;
      -- --dbms_output.PUT_LINE('TERMINA FLUJo SENI :: '||PPIDM||'-'||VSALIDA);

             --insert into twpasow(valor1, valor2, valor3, VALOR4, valor5)
            --values('termina el proceso SENI all  ',PPIDM,Pcode,pno_serv, VSALIDA );

      END IF;

       ----vamos a mandar la nueva parte insertar el cargo de mez gratis para utelx y conect glovicx 24.08.022
       --- se agrega validación para certificaciones MES GRATIS glovicx 19.08.022--
        --  esto es UNICAMENTE PARA LAS PLATAFORMAS DE MES GRATIS
      begin

        select distinct 'Y'
          INTO vaccesorio
            from zstpara
              where 1=1
                and ZSTPARA_MAPA_ID  = 'MES_GRATIS'
                and ZSTPARA_PARAM_ID = pcode;
         exception when others then

              vaccesorio  := 'N';
          end;

         -- insert into twpasow(valor1, valor2, valor3, VALOR4, valor5, valor6, VALOR7)
          --          Values('antes sdo insert TBRAA_NO_MES GRATIS:',ppidm,pno_serv, VCODE_DTLX, vgratis, vsal_dif, SYSDATE  );
          --           COMMIT;

       IF  vaccesorio = 'Y'  THEN
            vgratis  :=  PKG_SERV_SIU.F_ONE_FREE ( PPIDM, PCODE  ) ;

          IF vgratis = 'EXITO'  THEN

              BEGIN
                select distinct TBBDETC_DETAIL_CODE, TBBDETC_DESC
                      INTO VCODE_DTLX, VDESC_DTL
                   from zstpara, TBBDETC T
                     where 1=1
                      AND SUBSTR(F_GetSpridenID(Ppidm),1,2)||ZSTPARA_PARAM_DESC = T.TBBDETC_DETAIL_CODE
                      and ZSTPARA_MAPA_ID  = 'MES_GRATIS'
                      and ZSTPARA_PARAM_ID = PCODE;
                EXCEPTION WHEN OTHERS THEN
                NULL;
                 -- insert into twpasow(valor1, valor2, valor3, VALOR4, valor5, valor6, VALOR7)
                 --   Values('ERROR# 2.0 BUSANCO CODETL INSERTA TBRAA_NO_MES GRATIS:',ppidm,pno_serv, VCODE_DTLX, vgratis, vsal_dif, SYSDATE  );
                 --    COMMIT;
                 VCODE_DTLX:= NULL;
                 VDESC_DTL := NULL;

              END;

           vsal_dif :=   BANINST1.PKG_SERV_SIU.F_INSERT_CARTERA (PCODE,PPIDM,LTERM,VCODE_DTLX, round(vmonto),VDESC_DTL,PNO_SERV,'MESGRATIS', f_inicio,Vstudy,Vpparte,vcode_curr, vfeed,vsal_notran );

          -- insert into twpasow(valor1, valor2, valor3, VALOR4, valor5, valor6, VALOR7)
          ---          Values('entro a gratis segunda insert TBRAA_NO_MES GRATIS:',ppidm,pno_serv, VCODE_DTLX, vgratis, vsal_dif, SYSDATE  );
          --           COMMIT;

          END IF;
        --  insert into twpasow(valor1, valor2, valor3, VALOR4, valor5, valor6, VALOR7)
         --   Values('DENTRO INSERTA TBRAA_NO_MES GRATIS:',ppidm,pno_serv, VCODE_DTLX, vgratis, vtran_pay, SYSDATE  );
          --   COMMIT;

        END IF;


   end loop;


       ----------------si el servicio es nivelacion entonces inserta el horario------
    IF PCODE IN ( 'NIVE', 'NABA') and VSALIDA = 'EXITO'  then
     ------------calcula el periodo  que ahorita es diferente el de tbracce y el del horario preguntar como debrias er

         ---------aqui debera ir el inserta horario fase 2
             PKG_SERV_SIU.P_inserta_horario ( ppidm,  pcode, vperiodo, vcamp, PNO_SERV, pregreso )  ;

         IF pregreso = 'EXITO'  then
             VSALIDA   := 'EXITO';
           ELSE
           VSALIDA   := sqlerrm;

         END IF;

      ELSIF PCODE = 'NIVG' THEN
      --dbms_output.PUT_LINE('SALIDA inserta horario NIVG:.  ' || VSALIDA );

      ---------calcula el periodo  que ahorita es diferente el de tbracce y el del horario preguntar como debrias er
       --     insert into twpasow(valor1, valor2, valor3, VALOR4, valor5, valor6, VALOR7)
       -- Values('entro ANTES DE HORArio:',ppidm,pcode, vperiodo, vcamp,pno_serv, pregreso  );


         ---------aqui debera ir el inserta horario fase 2
         begin
           vsalida :=   PKG_SERV_SIU.f_inserta_horario_NIVG ( ppidm,  pcode, PNO_SERV )  ;
         exception when others THEN

          --insert into twpasow(valor1, valor2, valor3, VALOR4, valor5, valor6, VALOR7)
           --Values(' ERROR  DE HORArio:',ppidm,pcode, vperiodo, vcamp,pno_serv, vsalida  );

            ----dbms_output.PUT_LINE('ERROR EN PROC INSRT HORARIO: '||vsalida   );
            pregreso  := 'EXITO';
        end;

       --   insert into twpasow(valor1, valor2, valor3, VALOR4, valor5, valor6, VALOR7)
      --  Values('entro despues de insert horario_nive:',ppidm,pno_serv, vsalida, vsalida, vsal_dif, SYSDATE  );

         IF VSALIDA = 'EXITO'  then
             VSALIDA   := 'EXITO';

           ELSE
           VSALIDA   := sqlerrm;

         END IF;
        ----dbms_output.PUT_LINE('SALIDA DE desp de ejcuta horario nivegX:.  ' || VSALIDA );
      null;
      end if;



-------SI ES EL CAMPUS UNICA  EL SERVICIO SE LLAMA DIFERENTE GLOVICX 23/11/20
   IF PCODE IN ('EXTR','TISU') then
     ------------calcula el periodo  que ahorita es diferente el de tbracce y el del horario preguntar como debrias er

         ---------aqui debera ir el inserta horario fase 2
       pregreso:= PKG_SERV_SIU.F_inserta_horario_UNICA ( ppidm,  pcode, vperiodo, vcamp, PNO_SERV )  ;

         IF pregreso = 'EXITO'  then
             VSALIDA   := 'EXITO';
           ELSE
           VSALIDA   := sqlerrm;

         END IF;

      else
      ----dbms_output.PUT_LINE('SALIDA DIFERENTE DE NIVELACIONX:.  ' || VSALIDA );

      null;
      end if;

-------------


   ----dbms_output.PUT_LINE('SALIDA ANTES DE EXITO FINAL DEL EJEMPLO:.  ' || VSALIDA );

    IF  VSALIDA   = 'EXITO'  then


      -------SE ACTUALIZA EL NUMERO DE TRANSACCION ----- si es un exito  solo el accesorio no el envio
            begin
               UPDATE  svrsvpr
                   SET SVRSVPR_ACCD_TRAN_NUMBER = lv_trans_number
                where SVRSVPR_SRVC_CODE = PCODE
                 AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                -- and  SVRSVPR_ACCD_TRAN_NUMBER = 0
                ;
             exception when others then
             null;
            -- VSALIDA   := SQLERRM;
               
             end;


            ---------se envia el mail a los alumnos si todo sale bien ya no se va enviar por aqui se construyo algo desde python
       --VSALIDA_MAIL:= BANINST1.PKG_SERV_SIU.F_envia_mail (ppidm , pno_serv,pcode , vmonto ) ;

--      
            COMMIT;
          RETURN (VSALIDA);

     else
        --   null;
          VSALIDA   := sqlerrm; --'ERROR';
          --dbms_output.PUT_LINE('SALIDA EN NOOO__ERROR_1CC  :.  ' || VSALIDA );
           ROLLBACK;
           --------- baja el servicio que ya habia insertado---
              UPDATE  svrsvpr
                   SET SVRSVPR_SRVS_CODE     = 'CA',
                   SVRSVPR_INT_COMMENT       = VSALIDA
                where SVRSVPR_SRVC_CODE      = PCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                AND  SVRSVPR_PIDM            = PPIDM
                ;
            COMMIT;
            RETURN (VSALIDA);
    end if;

end if; --termina el IF inicial para saber si se ejecuta la funcion de cargos dif o el flujo normal

Exception When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error :'||sqlerrm;
   ----dbms_output.PUT_LINE('ERROOR EN TCARTERA:.  ' || VSALIDA );---------aqui manda elmensaje de error a vic para probar la funcionalidad del mail y checar los posibles errores
  --VSALIDA:=VSALIDA||BANINST1.PKG_SERV_SIU.F_envia_mail (ppidm , pno_serv,pcode , vmonto ) ;
--    insert into twpasow(valor1, valor2, valor3, VALOR4, valor5, valor6, VALOR7)
--     values('Error_GRAL_SIU_SERV',ppidm,pno_serv, pcode, vmonto, SYSDATE, SUBSTR(VSALIDA,1,100)  );

  ROLLBACK;
  RETURN (VSALIDA);



END  F_TCARTERA;


FUNCTION F_VALIDA_MATERIA (PPIDM NUMBER ) Return VARCHAR2  IS


 CONTADOR  NUMBER;
 VSALIDA   varchar2(300);

BEGIN

SELECT COUNT(DATOS.MATERIA) CUENTA
INTO CONTADOR
FROM (
SELECT (qq.ssbsect_subj_code || qq.ssbsect_crse_numb)  materia
          ,   CASE
                   WHEN qq.ssbsect_seq_numb IS NULL
                   THEN
                      SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                   ELSE
                      SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
            END    nombre_materia,
            so.SORLCUR_PROGRAM  as programa
            ,SO.SORLCUR_PIDM  as pidm
         FROM ssbsect qq, sfrstcr cr, shrgrde sh, sorlcur so, stvterm x, spriden sp
           WHERE  1=1
               AND cr.sfrstcr_pidm = pPidm --fget_pidm('010075696')
               AND cr.sfrstcr_term_code =qq.ssbsect_term_code
               AND cr.sfrstcr_crn = qq.ssbsect_crn
               AND sh.shrgrde_code = cr.SFRSTCR_GRDE_CODE
               and sh.SHRGRDE_LEVL_CODE = cr.SFRSTCR_LEVL_CODE
               AND sh.shrgrde_passed_ind = 'N'
               and cr.SFRSTCR_GRDE_CODE is not null
               AND so.SORLCUR_LMOD_CODE = 'LEARNER'
               AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS')
               AND sh.shrgrde_levl_code = so.SORLCUR_LEVL_CODE
               AND cr.sfrstcr_pidm      = so.sorlcur_pidm
               AND so.sorlcur_term_code = x.stvterm_code
               AND sp.spriden_change_ind IS NULL
               and cr.sfrstcr_pidm =  SP.SPRIDEN_PIDM
     minus
        SELECT   qq.ssbsect_subj_code || qq.ssbsect_crse_numb  mate
           , CASE
                   WHEN qq.ssbsect_seq_numb IS NULL
                   THEN
                      SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                   ELSE
                      SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
            END    nombre_materia,
            so.SORLCUR_PROGRAM  as programa
            ,SO.SORLCUR_PIDM  as pidm
          FROM ssbsect qq, sfrstcr cr, sorlcur so,  stvterm x, spriden sp
            WHERE  1=1
               AND cr.sfrstcr_pidm = Ppidm --fget_pidm('010075696')
               AND cr.sfrstcr_term_code =qq.ssbsect_term_code
               AND cr.sfrstcr_crn = qq.ssbsect_crn
               and cr.SFRSTCR_GRDE_CODE is null
               and cr.SFRSTCR_RSTS_CODE = 'RE'
               AND so.SORLCUR_LMOD_CODE = 'LEARNER'
               AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS')
               AND cr.sfrstcr_pidm =   so.sorlcur_pidm
               AND so.sorlcur_term_code = x.stvterm_code
               AND sp.spriden_change_ind IS NULL
               and cr.sfrstcr_pidm =  SP.SPRIDEN_PIDM
        ) DATOS
  WHERE 1=1
  ;

  IF CONTADOR > 0  THEN

  VSALIDA := 'SI';  -----SI ESQUE SI TIENE MATERIAS PARA NIVELACION
  RETURN (VSALIDA) ;

  ELSE

  VSALIDA := 'NO ';
  RETURN (VSALIDA) ;

  END IF;


Exception When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error :'||sqlerrm;
   ----dbms_output.PUT_LINE('ERROOR EN  FVALIDA_MATERIA:.  ' || VSALIDA );
    RETURN (VSALIDA);

END  F_VALIDA_MATERIA;

FUNCTION F_CONSULTA_SERV (pPIDM in VARCHAR2 ) Return PKG_SERV_SIU.CONSULTA_TYPE
IS
--
 vl_error   VARCHAR2(1000);

 CUR_CONSULTA      BANINST1.PKG_SERV_SIU.CONSULTA_TYPE;
 ---------SE CONCATENA EL NUM.  DE SERV Y MATERIA EN LA DESCRIPCION PARA DAR MAS CLARIDAD GLOVICX 03/012/2019-----
 -- SE ARREGLA EL CURSOR PRINCIPAL POR QUE TRAIA EL ENVIO INTERNACIONAL COMO UN CONCEPTO APARTE ESTE CURSOR SE USA EN LA PANTALLA DE HISTORIAL GLOVICX 24/06/021
 -- este cambio se hizo para que en el historial nos indique si hay PAGO_PARCIAL, por eso se puso solo la funcion de VICRMZ 22/072021- aun sin liberar por fernando
-- ajuste para poner los nombre de los estatus corecto nive_cero V3 glovicx 11.02.2025




 begin
    NULL;
      OPEN CUR_CONSULTA  FOR
                             SELECT DATOS.no_solicitud
                              ,DATOS.DESCU||'( '||DATOS.no_solicitud||DATOS.MATERIA||')'  descripcion
                          /*    , case when  decode(DATOS.estatus_v2,'PA','PAGADO','CA','CANCELADO','AC','ACTIVO', 'PR','PROCESO','CL', 'CONCLUIDO' ) =  upper( (select f_valida_pago_accesorio (PPIDM,DATOS.no_trans ) from dual )) then
                                 (select f_valida_pago_accesorio (PPIDM,DATOS.no_trans ) from dual )
                                 ELSE
                                          decode(DATOS.estatus_v2,'PA','PAGADO','CA','CANCELADO','AC','ACTIVO','CL', 'CONCLUIDO', 'PR','PROCESO',DATOS.estatus_v2  )
                              end estatus  */
                              ,ESTATUS
                              , ( select sum(nvl(TBRACCD_BALANCE,0))
                                    from tbraccd
                                    where 1=1
                                    AND tbraccd_pidm =PPIDM
                                    AND TBRACCD_CROSSREF_NUMBER  =  DATOS.no_solicitud    )  costo
                             , datos.FECHA_ACTV
                             , datos.costo_env
                             , datos.code_serv
                        FROM
                        (
                        select distinct
                                SVRSVPR_PROTOCOL_SEQ_NO as no_solicitud,
                                SVVSRVC_DESC  DESCU,
                                CASE  WHEN V.SVRSVPR_SRVC_CODE = 'NIVE' THEN
                                 (select DISTINCT '--' || SVRSVAD_ADDL_DATA_CDE  AS MATERIA
                                             from svrsvpr vV,SVRSVAD VA
                                            where VV.SVRSVPR_SRVC_CODE = V.SVRSVPR_SRVC_CODE
                                            AND  VV.SVRSVPR_PROTOCOL_SEQ_NO = V.SVRSVPR_PROTOCOL_SEQ_NO
                                            AND  VV.SVRSVPR_PIDM    = V.SVRSVPR_PIDM
                                            and  VV.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                            and  va.SVRSVAD_ADDL_DATA_SEQ = '2'  )
                              ELSE ''
                             END MATERIA ,
                                --SVVSRVS_desc AS servicio,
                                SVVSRVS_desc AS  ESTATUS,
                                SVRSVPR_PROTOCOL_AMOUNT  AS costo2,
                                 SVRSVPR_ACTIVITY_DATE   AS FECHA_ACTV
                               , ( select distinct STVWSSO_CHRG from STVWSSO
                                   where STVWSSO_CODE  =  v.SVRSVPR_WSSO_CODE )  as costo_env
                                ,SVRSVPR_SRVC_CODE      as code_serv
                                ,SVRSVPR_ACCD_TRAN_NUMBER no_trans
                                ,f_valida_pago_accesorio (PPIDM,v.SVRSVPR_ACCD_TRAN_NUMBER ) estatus_serv
                                ,V.SVRSVPR_SRVS_CODE   estatus_v2
                        from SVRSVPR v, SVVSRVS d, SVVSRVC f
                        WHERE 1=1
                        and  v.SVRSVPR_SRVC_CODE = f.SVVSRVC_CODE
                        and  v.SVRSVPR_SRVS_CODE  =  d.SVVSRVS_CODE
                        AND  V.SVRSVPR_PIDM      = ppidm --fget_pidm('010030702')
                        and  v.SVRSVPR_SRVC_CODE  IN  (SELECT zstpara_param_id
                                                 FROM  zstpara
                                                 WHERE 1=1
                                                 AND zstpara_mapa_id IN ('CERTIFICA_1SS','AUTOSERVICIOSIU') )
                         ORDER BY  SVRSVPR_PROTOCOL_SEQ_NO DESC
                        ) DATOS
                         WHERE 1=1
                         order by 1 desc;


 --------creo que esta version se hizo para colf diferida pero hay que revisar por que le pega a los demas acceorios que no son diferidos

 /*   SELECT DATOS.no_solicitud,
      DATOS.DESCU||'( '||DATOS.no_solicitud||DATOS.MATERIA||')'
     ,case when  decode(DATOS.estatuss,'PA','PAGADO','CA','CANCELADO','AC','ACTIVO' ) =  upper( (select f_valida_pago_accesorio (PPIDM,DATOS.no_trans ) from dual )) then
         (select f_valida_pago_accesorio (PPIDM,DATOS.no_trans ) from dual )
         ELSE
                  decode(DATOS.estatuss,'PA','PAGADO','CA','CANCELADO','AC','ACTIVO','CL', 'CONCLUIDO',DATOS.estatuss  )
      end estatus
      , ( select sum(TBRACCD_BALANCE)
            from tbraccd
            where 1=1
            AND tbraccd_pidm =PPIDM
            AND TBRACCD_CROSSREF_NUMBER  =  DATOS.no_solicitud    )  costo
     , datos.FECHA_ACTV
     , datos.costo_env
     , datos.code_serv
FROM
(
select distinct
        SVRSVPR_PROTOCOL_SEQ_NO as no_solicitud,
        SVVSRVC_DESC  DESCU,
        CASE  WHEN V.SVRSVPR_SRVC_CODE = 'NIVE' THEN
         (select DISTINCT '--'||SUBSTR(SVRSVAD_ADDL_DATA_CDE,1,decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1))-1) AS MATERIA
                    --INTO VNO_DOCTO
                    from svrsvpr vV,SVRSVAD VA
                    where VV.SVRSVPR_SRVC_CODE = V.SVRSVPR_SRVC_CODE
                    AND  VV.SVRSVPR_PROTOCOL_SEQ_NO = V.SVRSVPR_PROTOCOL_SEQ_NO
                    AND  VV.SVRSVPR_PIDM    = V.SVRSVPR_PIDM
                    and  VV.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                    and  va.SVRSVAD_ADDL_DATA_SEQ = '2'  )
      ELSE ''
     END MATERIA ,
        --SVVSRVS_desc AS servicio,
        SVVSRVS_desc AS  ESTATUS,
        SVRSVPR_PROTOCOL_AMOUNT  AS costo2,
         SVRSVPR_ACTIVITY_DATE   AS FECHA_ACTV
       , ( select distinct STVWSSO_CHRG from STVWSSO
           where STVWSSO_CODE  =  v.SVRSVPR_WSSO_CODE )  as costo_env
        ,SVRSVPR_SRVC_CODE      as code_serv
        ,SVRSVPR_ACCD_TRAN_NUMBER no_trans
         ,V.SVRSVPR_SRVS_CODE  as estatuss
from SVRSVPR v, SVVSRVS d, SVVSRVC f
WHERE 1=1
and  v.SVRSVPR_SRVC_CODE = f.SVVSRVC_CODE
and  v.SVRSVPR_SRVS_CODE  =  d.SVVSRVS_CODE
AND  V.SVRSVPR_PIDM      = ppidm --fget_pidm('010030702')
and  v.SVRSVPR_SRVC_CODE   IN (select DISTINCT ZSTPARA_PARAM_ID from ZSTPARA
                                  WHere  ZSTPARA_MAPA_ID like ('AUTOSERV%') )
 ORDER BY  SVRSVPR_PROTOCOL_SEQ_NO DESC

 ) DATOS
 WHERE 1=1
 order by 1 desc;
*/

        return CUR_CONSULTA;

 Exception
         When others  then
         vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || SUBSTR(sqlerrm,1,950) ;
           ---return CUR_CAMPOS;
 end F_CONSULTA_SERV;




FUNCTION F_CANCELA_SERV (PPIDM NUMBER, NO_SERV NUMBER, PCANCE VARCHAR2 DEFAULT NULL ) Return VARCHAR2  IS


CONTADOR        NUMBER;
VSALIDA         varchar2(400):= 'EXITO';
PPCODE          VARCHAR2(4);
SALIDA_TBRA     VARCHAR2(1000);
vmateria        VARCHAR2(12);
VSALIDA_HORA    VARCHAR2(400) := 'EXITO' ;
VDIAS           NUMBER:= 0;
vperiodo        VARCHAR2(12);
VFECHA_INICIO   VARCHAR2(14);
vcampus         VARCHAR2(3);
VSALIDA_stume   varchar2(500);
VCOMENTARIO     VARCHAR2(20);
vestatus        varchar2(4);

--se agrego la funcionalidad de cancelacion de univ. insurgentes UIN glovicx 04/06/2021

BEGIN

         begin

                 select distinct  t.campus
                   INTO  vcampus
                 from tztprog t
                  where 1=1
                  and  t.pidm = PPIDM
                  and t.sp = ( select max(t2.sp) from tztprog t2
                               where 1=1
                                and t2.pidm = t.pidm);

          EXCEPTION WHEN OTHERS THEN
                vcampus    := NULL;
          END;
        ----dbms_output.put_line('fcancela serv inicio '|| PPIDM||'-'|| NO_SERV||'-'|| vcampus);

------------------BUCAMOS PRIMERO EL CODE SERVICES--LA VARIABLE VCOMENTARIO= NULL ES QUE NO ES DIFERIDO
        BEGIN

                SELECT DISTINCT SVRSVPR_SRVC_CODE, SVRSVPR_STEP_COMMENT,SVRSVPR_SRVS_CODE
                  INTO PPCODE, VCOMENTARIO, vestatus
                FROM SVRSVPR
                   WHERE 1=1
                        AND  SVRSVPR_PIDM      =  PPIDM
                        AND SVRSVPR_SRVS_CODE != 'CA'
                        AND SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV;

        EXCEPTION WHEN OTHERS THEN
        PPCODE := NULL;
        VCOMENTARIO := NULL;
        vestatus    :=null;
        END;

CONTADOR := 0;




  ----dbms_output.put_line('fcancela serv inicio '|| PPIDM||'-'|| NO_SERV||'-'|| vcampus||'-'|| PPCODE);


 IF PPCODE = 'COLF'  AND VCOMENTARIO = 'DIFERIDA'  then
  ----dbms_output.put_line('fcancela serv inicio2 '|| PPIDM||'-'|| NO_SERV||'-'|| vcampus||'-'|| PPCODE);
        -- EJECUTA LA CANCELACIÓN DIFERIDA--- GLOVICX 11/06/2021 ESTE CAMBIO SE VA CON COLF POR NIVEL

     VSALIDA :=  BANINST1.PKG_SERV_SIU.F_CANCELA_COLF_DIF  (PPIDM , NO_SERV , PPCODE   ) ;
       -- aquie se va ejecutar la funcion de reza la que cancela la cartera de diferidos



ELSIF PPCODE IS NOT NULL THEN

          if PCANCE is not null then -- se lanza el proceso especial de cancelación glovicx 25.10.022

              SALIDA_TBRA :=  pkg_serv_siu.P_CAN_SERV_ESP  ( PPCODE, PPIDM,NO_SERV,'WWW_CAN_ESP' ) ;
               --dbms_output.put_line('SALIDA DE P_CAN_SERV_esp?? '||SALIDA_TBRA);
          else
               SALIDA_TBRA :=  pkg_serv_siu.P_CAN_SERV_ALL  ( PPCODE, PPIDM,NO_SERV,'WWW_USER_CAN' ) ;
          end if;


      ----dbms_output.put_line('valida pagado o no?? '||SALIDA_TBRA);


 IF  SALIDA_TBRA = 'PAGADO' THEN
     RETURN ( 'PAGADO' );
       --------------------esta seccion es exlusiva para cancelar el horario de nive S ELE AGREGA LOS SERVISIO DE EXTR Y TISU GLOVICX 24/11/20
      
   
   ELSIF SALIDA_TBRA = 'EXITO' AND PPCODE IN ('NIVE', 'NIVG', 'NABA') THEN



             BEGIN
                select
                      case  when INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1) > 0 then
                          --SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1)
                          SVRSVAD_ADDL_DATA_CDE
                           else
                          --SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10)-1 )
                          SVRSVAD_ADDL_DATA_CDE
                      end as materia
                    INTO  vmateria
                 from svrsvpr v,SVRSVAD VA
                        where SVRSVPR_SRVC_CODE = PPcode
                           AND  SVRSVPR_PIDM   = ppidm
                            AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  NO_SERV
                           and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                           and va.SVRSVAD_ADDL_DATA_SEQ in ( 2) ; ------el valor 2 es para la materia
              EXCEPTION WHEN OTHERS THEN
                VMATERIA :='';

              END;


 VSALIDA_HORA :=  F_cancela_horario_NIVE ( ppidm , vmateria ) ;

  ELSIF SALIDA_TBRA = 'EXITO' AND PPCODE IN ('EXTR','TISU')  THEN
  --- aqui entra para UNI y UIN

             BEGIN
                select
                      SVRSVAD_ADDL_DATA_CDE  AS MATERIA
                    INTO  vmateria
                 from svrsvpr v,SVRSVAD VA
                        where SVRSVPR_SRVC_CODE = PPcode
                           AND  SVRSVPR_PIDM   = ppidm
                            AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  NO_SERV
                           and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                           and va.SVRSVAD_ADDL_DATA_SEQ in ( 2) ; ------el valor 2 es para la materia
              EXCEPTION WHEN OTHERS THEN
                VMATERIA :='';

              END;


        IF  vcampus = 'UIN'  THEN

           ----dbms_output.put_line('entra a la ultima parte sztume inicio '|| VSALIDA_HORA );

         -----SE CALCULA LA FECHA DE INICIO DEL SERVICIO POR QUE A PARTIE DE AHI SE CUENTAN LOS 4 DIAS PARA SU CANCELACIÓN UIN GLOVIC 18/05/2021
           BEGIN    -----------------recupera la parte de periodo que solicito el alumno
              select substr(rango,1, instr(rango,'-AL-',1 )-1) as fecha_ini
                     INTO VFECHA_INICIO
                from (
                select
                      SVRSVAD_ADDL_DATA_DESC  rango
                         from svrsvpr v,SVRSVAD VA
                            where SVRSVPR_SRVC_CODE = PPCODE
                            AND  SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV
                              AND  SVRSVPR_PIDM    = Ppidm
                               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                               and va.SVRSVAD_ADDL_DATA_SEQ = '7' --- ES EL MISMO DEL PARTE DE PERIODO
                               ) ;


          EXCEPTION WHEN OTHERS THEN
            VFECHA_INICIO:=NULL;
          --insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7)
          --values( 'Dentro error F_CANCELA_JOB-fecha UIN',Ppidm, SYSDATE,VFECHA_INICIO ,PPCODE,NO_SERV, VSALIDA  );

          END;

                          begin
                                 select *
                                         INTO   vperiodo
                                    from (
                                        SELECT DISTINCT sobptrm_term_code codigo
                                              FROM  sobptrm so, spriden
                                                       WHERE  1=1
                                                              and SOBPTRM_PTRM_CODE = '1'
                                                              and  SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                                                              AND  SUBSTR (SOBPTRM_TERM_CODE, 5, 2) IN (81,82,83  )
                                                             and substr(sobptrm_term_code,1,2)   = SUBSTR(F_GETSPRIDENID(Ppidm),1,2)
                                                             and SOBPTRM_END_DATE  >= sysdate

                                                             order by 1 desc

                                          ) data
                                          where 1=1
                                          and rownum <2;


                                ---nueva regla que se dio en la junta del dia 22/02/021  VictorR y Fernando
                                -- para los casos de EXTR y TISU si lleva la fecha de inicio de la parte del periodo glovicx



                        exception when others then
                          vperiodo := null;

                          ----dbms_output.put_line('error en calcular el periodo y finicio EXTR:  '|| sqlerrm);
                        end;


         BEGIN
              select DISTINCT  decode(nvl(SZRRCON_VIG_PAG,0),0,1,SZRRCON_VIG_PAG) dias
                   INTO VDIAS
                from szrrcon z, svrsvpr v
                where 1=1
                and Z.SZRRCON_SRVC_CODE  = V.SVRSVPR_SRVC_CODE
                --and SVRSVPR_SRVC_CODE = 'EXTR'
                AND V.SVRSVPR_CAMP_CODE IS NOT NULL
                and SZRRCON_VIG_PAg is not null
                AND SZRRCON_SRVS_CODE = 'AC'
                and  V.SVRSVPR_CAMP_CODE =VCAMPUS
                and SZRRCON_SRVC_CODE = PPCODE
               ;
           EXCEPTION WHEN OTHERS THEN
            VDIAS:=NULL;


          END;
          ------COMPARA LA FECHA DE INICIO PARA VER SI CUANDO LO CANCELA INSERGENTES 18/05/2021
             ----dbms_output.put_line('antes de lanzar el estume '|| VFECHA_INICIO||'-'|| VDIAS  );
              IF   TRUNC(SYSDATE) >= TO_DATE(VFECHA_INICIO, 'DD/MM/YYYY') + VDIAS THEN
                 --insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7)
                 --values( 'Dentro F_CANCELA_X USUARIO-fecha_iniCio+DIAS UIN',Ppidm, SYSDATE,VFECHA_INICIO ,PPCODE, NO_SERV, VSALIDA  );COMMIT;

                  VSALIDA_stume := PKG_NIVE_AULA.F_inst_SZSTUME (vmateria  , Ppidm ,BANINST1.F_GetSpridenID(Ppidm) ,VFECHA_INICIO  , vperiodo ,NO_SERV  ,'DD'  ) ;
                  ----dbms_output.put_line('salida despues de insert SZTUME--DD'||VSALIDA_stume);

                 VSALIDA_HORA:= VSALIDA_stume;---igualo las salidas para ver si es exito o error

              END IF;
       END IF;

                 if VSALIDA_HORA = 'EXITO' then   ---si salida estume es exito entonces ya hace la baja de materia en banner asi esta bien por que hay una validacion en estume primero

                    VSALIDA_HORA :=  F_cancela_horario_NIVE ( ppidm , vmateria ) ;

                END IF;

    END IF;

            IF VSALIDA_HORA = 'EXITO'  THEN
                null;
              else
              SALIDA_TBRA := VSALIDA_HORA;
             end if;



     IF SALIDA_TBRA = 'EXITO'   AND VSALIDA_HORA ='EXITO'  THEN


         UPDATE SVRSVPR v
            SET  SVRSVPR_SRVS_CODE = 'CA',
                 SVRSVPR_USER_ID   = 'WWW_CAN_ALUMN',
                 SVRSVPR_ACTIVITY_DATE = SYSDATE
            WHERE 1=1
            AND  V.SVRSVPR_PIDM   = PPIDM
           -- AND SVRSVPR_SRVS_CODE IN ('AC','CA')  SE LE QUITO ESTA seccion porla pantalla de cancelación especial. glovicx 25.10.022
            AND SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV;
             CONTADOR :=   sql%rowcount;
          ----dbms_output.PUT_LINE('CACELACION FINAL DEL SERVICIO Y CARTERA'||PPIDM ||'-'|| NO_SERV );

       VSALIDA := 'EXITO';

            RETURN (VSALIDA) ;

       ELSE

         RETURN (SALIDA_TBRA ||'-'||VSALIDA_HORA) ;

      END IF;

    COMMIT;



END IF;


 Exception When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error :'||sqlerrm;
   ----dbms_output.PUT_LINE('ERROOR EN  FCANCELA_SERVICIOS:.  ' || VSALIDA );
    RETURN (VSALIDA);

END  F_CANCELA_SERV;

FUNCTION F_MOTIVO_BAJA (pCODE in VARCHAR2 ) Return PKG_SERV_SIU.BAJA_TYPE
IS
 cur_motivo_baja BANINST1.PKG_SERV_SIU.BAJA_TYPE;


 begin
        open cur_motivo_baja for
                                SELECT STVWRSN_CODE, STVWRSN_DESC
                                FROM STVWRSN2;

       return cur_motivo_baja;
  Exception
            When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.cur_motivo_baja: ' || sqlerrm;
           return cur_motivo_baja;
 end F_MOTIVO_BAJA;

FUNCTION F_BAJA_TEM (PPIDM NUMBER, NO_SERV NUMBER ) Return VARCHAR2  IS


 CONTADOR  NUMBER;
 VSALIDA   varchar2(300);

BEGIN
NULL;




  VSALIDA   := 'EXITO';
 RETURN   VSALIDA;


Exception When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
   VSALIDA:='Error :'||sqlerrm;
   ----dbms_output.PUT_LINE('ERROOR EN  FCANCELA_SERVICIOS:.  ' || VSALIDA );
   RETURN (VSALIDA);

END  F_BAJA_TEM;

FUNCTION F_CAMB_PROG (PPIDM NUMBER, PCODE  VARCHAR2, pcamp varchar2, plevel varchar2 ) Return VARCHAR2  IS

 CONTADOR  NUMBER;
 VSALIDA   varchar2(300);

---- SE AJUSTA PARA LA VERSION 2 CON RAUL 20.12.2024 del CAPR cambio de programa glovicx 10.01.2025

BEGIN

      SELECT COUNT (*)
        INTO contador
        FROM svrsrad
       WHERE     svrsrad_srvc_code = PCODE
             AND svrsrad_addl_data_title LIKE '%Nuevo Prog%';

      IF contador > 0
      THEN
         DELETE FROM NUEVOPROG2
               WHERE z_pidm = Ppidm;

         INSERT INTO NUEVOPROG2
              select distinct M.SMRPRLE_PROGRAM, 
              --M.SMRPRLE_PROGRAM_DESC,
                D.SZTDTEC_PROGRAMA_COMP descx,
                 PPIDM 
                from SZTPTRM z, sobptrm p, smrprle m, SZTDTEC D
                where 1=1
                and P.SOBPTRM_PTRM_CODE  = Z.SZTPTRM_PTRM_CODE
                and P.SOBPTRM_TERM_CODE  = Z.SZTPTRM_TERM_CODE
                and Z.SZTPTRM_PROGRAM    = M.SMRPRLE_PROGRAM
                --and SZTPTRM_CAMP_CODE =   M.SMRPRLE_CAMP_CODE
                and  SZTPTRM_LEVL_CODE =  M.SMRPRLE_LEVL_CODE
                and  SZTDTEC_PROGRAM =M.SMRPRLE_PROGRAM 
                and SZTPTRM_CAMP_CODE = pcamp
                and  SZTPTRM_LEVL_CODE = plevel
                AND SZTDTEC_MOD_TYPE != 'I'
                and trunc(SOBPTRM_START_DATE) >= trunc(sysdate);

         COMMIT;
      END IF;

  VSALIDA   := 'EXITO';
 RETURN   VSALIDA;

Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error CAMBIO DE PROGRAMA::: '||sqlerrm;

    RETURN (VSALIDA);

END F_CAMB_PROG;



FUNCTION F_FECHA_INI (pCODE in VARCHAR2, PCAMP IN VARCHAR2, PLEVEL IN VARCHAR2, PPROGRAMA VARCHAR2  ) Return PKG_SERV_SIU.FECHAS_TYPE
IS
 CUR_FECHAS BANINST1.PKG_SERV_SIU.FECHAS_TYPE;


 begin
        open CUR_FECHAS for
                          select distinct P.SOBPTRM_TERM_CODE, SUBSTR (stvterm_desc, 1, 6)
                         || '||'
                         || TO_CHAR (sobptrm_start_date, 'dd')
                         || ' de '
                         || INITCAP (TO_CHAR (sobptrm_start_date, 'fmmonth'))
                         || ' de '
                         || TO_CHAR (sobptrm_start_date, 'yyyy')
                            fecha_desc
from SZTPTRM z, sobptrm p, smrprle m, stvterm v
where 1=1
and P.SOBPTRM_PTRM_CODE  = Z.SZTPTRM_PTRM_CODE
and P.SOBPTRM_TERM_CODE  = Z.SZTPTRM_TERM_CODE
and Z.SZTPTRM_PROGRAM    = M.SMRPRLE_PROGRAM
and  z.SZTPTRM_LEVL_CODE =  M.SMRPRLE_LEVL_CODE
and  Z.SZTPTRM_TERM_CODE  =  V.STVTERM_CODE
and SZTPTRM_CAMP_CODE  = PCAMP
and  SZTPTRM_LEVL_CODE = PLEVEL
and Z.SZTPTRM_PROGRAM  = PPROGRAMA
and trunc(SOBPTRM_START_DATE) >= trunc(sysdate);


       return CUR_FECHAS;
  Exception
            When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.cur_motivo_baja: ' || sqlerrm;
           return CUR_FECHAS;
 end F_FECHA_INI;

FUNCTION F_FECHA_XINGRESAR (PCAMP IN VARCHAR2, PLEVEL IN VARCHAR2, PPROGRAMA VARCHAR2  ) Return PKG_SERV_SIU.FECHAS_TYPE
IS
 CUR_FECHAS BANINST1.PKG_SERV_SIU.FECHAS_TYPE;

 begin
        open CUR_FECHAS for
                       SELECT  sobptrm_start_date per_fecha, SUBSTR (stvterm_desc, 1, 6)
                        || '||'
                        || TO_CHAR (sobptrm_start_date, 'dd')
                        || ' de '
                        || INITCAP (TO_CHAR (sobptrm_start_date, 'fmmonth'))
                        || ' de '
                        || TO_CHAR (sobptrm_start_date, 'yyyy')
                        per_fecha_desc
                      --  ,  PPIDM
                    from SZTPTRM z, sobptrm p, smrprle m, stvterm v
                    where 1=1
                    and P.SOBPTRM_PTRM_CODE  = Z.SZTPTRM_PTRM_CODE
                    and P.SOBPTRM_TERM_CODE  = Z.SZTPTRM_TERM_CODE
                    and Z.SZTPTRM_PROGRAM    = M.SMRPRLE_PROGRAM
                    and  z.SZTPTRM_LEVL_CODE =  M.SMRPRLE_LEVL_CODE
                    and  Z.SZTPTRM_TERM_CODE  =  V.STVTERM_CODE
                    and SZTPTRM_CAMP_CODE  = PCAMP
                    and  SZTPTRM_LEVL_CODE = PLEVEL
                    and Z.SZTPTRM_PROGRAM  = PPROGRAMA
                    and trunc(SOBPTRM_START_DATE) >= trunc(sysdate);


       return CUR_FECHAS;
  Exception
            When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.cur_motivo_baja: ' || sqlerrm;
           return CUR_FECHAS;
 end F_FECHA_XINGRESAR;

FUNCTION F_PERXCURSAR (PPIDM NUMBER ) Return VARCHAR2  IS

 CONTADOR  NUMBER;
 VSALIDA   varchar2(300);

BEGIN


         DELETE FROM PERXCURSAR2
               WHERE z_pidm = Ppidm;

         INSERT INTO PERXCURSAR2
                 SELECT DISTINCT
                         sobptrm_term_code periodo,
                         stvterm_desc per_desc,
                         spriden_pidm z_pidm
                    FROM spriden,
                         sobptrm,
                         stvterm,
                         saradap x
                   WHERE     spriden_pidm = Ppidm
                         AND spriden_change_ind IS NULL
                         AND sobptrm_ptrm_code = '1'
                         AND (   TRUNC (SYSDATE) BETWEEN sobptrm_start_date
                                                     AND sobptrm_end_date
                              OR sobptrm_start_date >= TRUNC (SYSDATE))
                         AND SUBSTR (sobptrm_term_code, 1, 2) =
                                SUBSTR (spriden_id, 1, 2)
                         AND STVTERM_TRMT_CODE NOT IN ('E')
                         AND stvterm_code = sobptrm_term_code
                         AND SUBSTR (stvterm_code, 5, 1) = '4'
                         AND saradap_pidm = spriden_pidm
                         AND saradap_term_code_entry != sobptrm_term_code
                         AND saradap_term_code_entry IN
                                (SELECT MAX (saradap_term_code_entry)
                                   FROM saradap xx
                                  WHERE x.saradap_pidm = xx.saradap_pidm)
                ORDER BY sobptrm_term_code;

         COMMIT;


  VSALIDA   := 'EXITO';
 RETURN   VSALIDA;

Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error CAMBIO DE PROGRAMA::: '||sqlerrm;

    RETURN (VSALIDA);

END F_PERXCURSAR;

/* Formatted on 30/09/2021 04:16:23 p. m. (QP5 v5.215.12089.38647) */
PROCEDURE P_CAN_SERV_JOB (PPCODE VARCHAR2, PPIDM NUMBER)
IS
   VSALIDA           VARCHAR2 (800);
   CONTADOR          NUMBER := 0;
   vdias             NUMBER;
   vservicio         VARCHAR2 (4);
   vcodigo_dtl       VARCHAR2 (6);
   vdescrp           VARCHAR2 (200);
   lv_trans_number   NUMBER := 0;
   vmateria          VARCHAR2 (14);
   VSALIDA_HORA      VARCHAR2 (200);
   SALIDA_TBRA       VARCHAR2 (200);
   VJOB2             VARCHAR2 (200);
   VFECHA_INICIO     VARCHAR2 (15);
   vmateriap         VARCHAR2 (20);
   vperiodo          VARCHAR2 (10);
   --vstst, vlevel, vcamp
   vfini             VARCHAR2 (12);
BEGIN
   FOR J
      IN (  SELECT DISTINCT
                   DECODE (NVL (SZRRCON_VIG_PAG, 0), 0, 1, SZRRCON_VIG_PAG)
                      dias,
                   SZRRCON_SRVC_CODE SERVICIO
              --INTO vdias, vservicio
              FROM szrrcon
             WHERE     1 = 1
                   AND SZRRCON_VIG_PAg IS NOT NULL
                   AND SZRRCON_SRVC_CODE IN
                          (SELECT zstpara_param_id
                                                 FROM  zstpara
                                                 WHERE 1=1
                                                 AND zstpara_mapa_id IN ('CERTIFICA_1SS','AUTOSERVICIOSIU')
                                                 AND ZSTPARA_PARAM_ID = NVL (PPCODE, ZSTPARA_PARAM_ID))
          --   GROUP BY SZRRCON_SRVC_CODE
          -- and SZRRCON_SRVS_CODE not in ( 'CA','PA' )
          ORDER BY 2, 1)
   LOOP
      ----dbms_output.PUT_LINE('REGS---'||'-'||J.DIAS||'-'||J.servicio);

      FOR jump
         IN (SELECT SVRSVPR_PROTOCOL_SEQ_NO seq_no,
                    SVRSVPR_PIDM pidm,
                    SVRSVPR_SRVC_CODE code,
                    SVRSVPR_RECEPTION_DATE fecha,
                    SVRSVPR_ACCD_TRAN_NUMBER no_tran,
                    SVRSVPR_TERM_CODE periodo,
                    SVRSVPR_CAMP_CODE CAMPUS
               FROM SVRSVPR v
              WHERE     1 = 1
                    AND v.SVRSVPR_SRVS_CODE IN ('AC')
                    AND TRUNC (v.SVRSVPR_RECEPTION_DATE) <= SYSDATE - J.DIAS
                    AND V.SVRSVPR_SRVC_CODE = J.SERVICIO
                    AND TRUNC (V.SVRSVPR_RECEPTION_DATE) >=
                           ADD_MONTHS (TRUNC (SYSDATE), -3)
                    -- AND SVRSVPR_DATA_ORIGIN !=  'BAJA_JOB'
                    --  and SVRSVPR_USER_ID = 'WWW_USER'
                    AND V.SVRSVPR_PIDM = NVL (ppidm, V.SVRSVPR_PIDM))
      LOOP
         ---ESTA EXCEPTION SE HACE SOLO PARA EXTR DE UIN'INSURGENTES' GLOVICX 18/05/2021
         IF J.SERVICIO = 'EXTR' AND JUMP.CAMPUS = 'UIN'
         THEN
            -----SE CALCULA LA FECHA DE INICIO DEL SERVICIO POR QUE A PARTIE DE AHI SE CUENTAN LOS 4 DIAS PARA SU CANCELACIÓN UIN GLOVIC 18/05/2021
            BEGIN -----------------recupera la parte de periodo que solicito el alumno
               SELECT SUBSTR (rango, 1, INSTR (rango, '-AL-', 1) - 1)
                         AS fecha_ini
                 INTO VFECHA_INICIO
                 FROM (SELECT SVRSVAD_ADDL_DATA_DESC rango
                         FROM svrsvpr v, SVRSVAD VA
                        WHERE     SVRSVPR_SRVC_CODE = J.SERVICIO
                              AND SVRSVPR_PROTOCOL_SEQ_NO = JUMP.seq_no
                              AND SVRSVPR_PIDM = JUMP.pidm
                              AND V.SVRSVPR_PROTOCOL_SEQ_NO =
                                     VA.SVRSVAD_PROTOCOL_SEQ_NO
                              AND va.SVRSVAD_ADDL_DATA_SEQ = '7' --- ES EL MISMO DEL PARTE DE PERIODO
                                                                );
            EXCEPTION
               WHEN OTHERS
               THEN
                  VFECHA_INICIO := NULL;
            --      insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7)
            --   values( 'Dentro error F_CANCELA_JOB-fecha UIN',JUMP.pidm, SYSDATE,VFECHA_INICIO ,J.SERVICIO,JUMP.seq_no, VSALIDA  );

            END;

            BEGIN
               SELECT DISTINCT
                      DECODE (NVL (SZRRCON_VIG_PAG, 0),
                              0, 1,
                              SZRRCON_VIG_PAG)
                         dias
                 INTO VDIAS
                 FROM szrrcon z, svrsvpr v
                WHERE     1 = 1
                      AND Z.SZRRCON_SRVC_CODE = V.SVRSVPR_SRVC_CODE
                      --and SVRSVPR_SRVC_CODE = 'EXTR'
                      AND V.SVRSVPR_CAMP_CODE IS NOT NULL
                      AND SZRRCON_VIG_PAg IS NOT NULL
                      AND SZRRCON_SRVS_CODE = 'AC'
                      AND V.SVRSVPR_CAMP_CODE = JUMP.CAMPUS
                      AND SZRRCON_SRVC_CODE = J.SERVICIO;
            EXCEPTION
               WHEN OTHERS
               THEN
                  VDIAS := NULL;
            END;

            ------COMPARA LA FECHA DE INICIO PARA VER SI CUANDO LO CANCELA INSERGENTES 18/05/2021

            IF TRUNC (SYSDATE) >=
                  TO_DATE (VFECHA_INICIO, 'DD/MM/YYYY') + VDIAS
            THEN
               --    insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7)
               --   values( 'Dentro F_CANCELA_JOB-fecha_iniCio+DIAS UIN',JUMP.pidm, SYSDATE,VFECHA_INICIO ,J.SERVICIO, JUMP.seq_no, VSALIDA  );COMMIT;

               SALIDA_TBRA := P_CAN_SERV_ALL (jump.code,
                                  Jump.pidm,
                                  Jump.seq_no,
                                  'WWW_CAN_AUTOM'); ------- ESTE PROCESO CANCELA LA CARTERA
            END IF;
         ELSE
            ----AQUIE NTRAN TODO LOS QUE NO SON EXTR Y INSURGENTE 18/05/021

            VSALIDA_HORA := 'EXITO';                    --reinicia la variable

            --  --dbms_output.PUT_LINE('REGS--ANTES tbracc-'||'-'||Jump.pidm||'-'||Jump.seq_no||'-'|| jump.code    );

            SALIDA_TBRA :=  P_CAN_SERV_ALL (jump.code,
                               Jump.pidm,
                               Jump.seq_no,
                               'WWW_CAN_AUTOM'
                               ); ------- ESTE PROCESO CANCELA LA CARTERA
         END IF;                                --AQUI CIERRA IF DE EXTR Y UIN



         --------------------esta seccion es exlusiva para cancelar el horario de NIVELACION
         IF SALIDA_TBRA = 'EXITO' AND jump.code IN ('NIVE','NABA'  )
         THEN
            BEGIN
               SELECT CASE
                         WHEN INSTR (SVRSVAD_ADDL_DATA_CDE, '|', 1) > 0
                         THEN
                            --SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1)
                            SVRSVAD_ADDL_DATA_CDE
                         ELSE
                            --SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10)-1 )
                            SVRSVAD_ADDL_DATA_CDE
                      END
                         AS materia
                 INTO vmateria
                 FROM svrsvpr v, SVRSVAD VA
                WHERE     SVRSVPR_SRVC_CODE = jump.code
                      AND SVRSVPR_PIDM = Jump.pidm
                      AND V.SVRSVPR_PROTOCOL_SEQ_NO = Jump.seq_no
                      AND V.SVRSVPR_PROTOCOL_SEQ_NO =
                             VA.SVRSVAD_PROTOCOL_SEQ_NO
                      AND va.SVRSVAD_ADDL_DATA_SEQ IN (2); ------el valor 2 es para la materia
            EXCEPTION
               WHEN OTHERS
               THEN
                  VMATERIA := '';
            END;

            NULL;
            VSALIDA_HORA := F_cancela_horario_NIVE (Jump.pidm, vmateria);
         
         ELSIF SALIDA_TBRA = 'EXITO' AND PPCODE IN ('EXTR', 'TISU')
         THEN
            BEGIN
               SELECT SVRSVAD_ADDL_DATA_CDE AS MATERIA
                 INTO vmateria
                 FROM svrsvpr v, SVRSVAD VA
                WHERE     SVRSVPR_SRVC_CODE = PPcode
                      AND SVRSVPR_PIDM = ppidm
                      AND V.SVRSVPR_PROTOCOL_SEQ_NO = Jump.seq_no
                      AND V.SVRSVPR_PROTOCOL_SEQ_NO =
                             VA.SVRSVAD_PROTOCOL_SEQ_NO
                      AND va.SVRSVAD_ADDL_DATA_SEQ IN (2); ------el valor 2 es para la materia
            EXCEPTION
               WHEN OTHERS
               THEN
                  VMATERIA := '';
            END;


            VSALIDA_HORA := F_cancela_horario_NIVE (ppidm, vmateria);

            ----dbms_output.PUT_LINE('REGS--Despus de ejecutar cancela horario ' ||'-'||Jump.pidm||'-'||Jump.seq_no||'-'|| VSALIDA_HORA    );


            IF VSALIDA_HORA = 'EXITO' AND JUMP.CAMPUS = 'UIN'
            THEN                      ---CAMBIO PARA UIN_V2 GLOVICX 28/05/2021
               BEGIN
                  SELECT SZTMACO_MATPADRE
                    INTO vmateriap
                    FROM sztmaco
                   WHERE 1 = 1 AND SZTMACO_MATHIJO = (vmateria);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vmateriap := NULL;
               ----dbms_output.put_line('ERROR  al calcular mako'||  jump.materia);
               -- verror  := 'no se pudo obtener materia padre -hijo'|| jump.materia;
               END;

               BEGIN
                  SELECT *
                    INTO vperiodo
                    FROM (  SELECT DISTINCT sobptrm_term_code codigo
                              FROM sobptrm so, spriden
                             WHERE     1 = 1
                                   AND SOBPTRM_PTRM_CODE = '1'
                                   AND SUBSTR (SOBPTRM_TERM_CODE, 5, 1) = '8'
                                   AND SUBSTR (SOBPTRM_TERM_CODE, 5, 2) IN
                                          (81, 82, 83)
                                   AND SUBSTR (sobptrm_term_code, 1, 2) =
                                          SUBSTR (F_GETSPRIDENID (jump.pidm),
                                                  1,
                                                  2)
                                   AND SOBPTRM_END_DATE >= SYSDATE
                          ORDER BY 1 DESC) data
                   WHERE 1 = 1 AND ROWNUM < 2;
               ---nueva regla que se dio en la junta del dia 22/02/021  VictorR y Fernando
               -- para los casos de EXTR y TISU si lleva la fecha de inicio de la parte del periodo glovicx



               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vperiodo := NULL;
               ----dbms_output.put_line('error en calcular el periodo y finicio EXTR:  '|| sqlerrm);
               END;

               ---revisamos la parte de periodo que escogio el alumno fechas ini y fin
               BEGIN
                  SELECT SUBSTR (SVRSVAD_ADDL_DATA_DESC,
                                 1,
                                 INSTR (SVRSVAD_ADDL_DATA_DESC, '-') - 1)
                            fini
                    INTO vfini
                    FROM SVRSVPR v, SVRSVAD va
                   WHERE     1 = 1
                         AND SVRSVPR_SRVC_CODE IN ('EXTR')
                         AND SVRSVPR_SRVS_CODE IN ('PA', 'AC')
                         AND v.SVRSVPR_PROTOCOL_SEQ_NO =
                                VA.SVRSVAD_PROTOCOL_SEQ_NO
                         AND SVRSVAD_ADDL_DATA_SEQ IN (7)
                         AND V.SVRSVPR_PIDM = jump.pidm
                         AND V.SVRSVPR_PROTOCOL_SEQ_NO = jump.seq_no;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     vfini := NULL;
               END;


               --INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3, VALOR4,VALOR5, VALOR6, VALOR7  )
               --VALUES('CANCELA JOB_ EXTR_ ANTE DE ENVIO SZTUME',Jump.pidm , vmateriap ,vfini, vperiodo, Jump.seq_no, SYSDATE  );


               VSALIDA_HORA :=
                  PKG_NIVE_AULA.F_inst_SZSTUME (
                     vmateriap,
                     Jump.pidm,
                     BANINST1.F_GetSpridenID (Jump.pidm),
                     vfini,
                     vperiodo,
                     Jump.seq_no,
                     'DD');
            END IF;
         END IF;

         IF VSALIDA_HORA = 'EXITO'
         THEN
            NULL;
         ELSE
            SALIDA_TBRA := VSALIDA_HORA;
         END IF;


         IF SALIDA_TBRA = 'EXITO'
         THEN
            UPDATE SVRSVPR v
               SET SVRSVPR_SRVS_CODE = 'CA',
                   SVRSVPR_USER_ID = 'WWW_CAN',
                   SVRSVPR_ACTIVITY_DATE = SYSDATE
             WHERE     1 = 1
                   AND V.SVRSVPR_PIDM = Jump.pidm
                   AND SVRSVPR_SRVS_CODE IN ('AC', 'CA')
                   AND SVRSVPR_PROTOCOL_SEQ_NO = Jump.seq_no;

            CONTADOR := SQL%ROWCOUNT;
         ----dbms_output.PUT_LINE('CACELACION FINAL DEL SERVICIO Y CARTERA'||Jump.pidm  ||'-'||  Jump.seq_no );

         END IF;


         IF CONTADOR > 0
         THEN
            VSALIDA := 'EXITO'; -----SI ESQUE SI TIENE MATERIAS PARA NIVELACION
         ---    RETURN (VSALIDA) ;
         ELSE
            VSALIDA := 'NO SE PUEDE CANCELAR YA ESTA EN PROCESO O PAGADO';
         END IF;

         COMMIT;
      END LOOP;
   END LOOP;

   -------------------------LANZA EL JOB2 --
   -- VJOB2:=  BANINST1.PKG_SERV_SIU.F_CAN_JOB2 ;
   VJOB2 := BANINST1.PKG_SERV_SIU.F_update_code_tbra;
EXCEPTION
   WHEN OTHERS
   THEN
      VSALIDA := 'Error :' || SQLERRM;

      --- RETURN   VSALIDA;

END P_CAN_SERV_JOB;

---------------------------------------------------------------
/* Formatted on 30/09/2021 04:14:55 p. m. (QP5 v5.215.12089.38647) */
FUNCTION P_CAN_SERV_ALL (PPCODE     VARCHAR2,
                         PPIDM      NUMBER,
                         NO_SERV    NUMBER,
                         PPUSER     VARCHAR2)
   RETURN VARCHAR2
IS
   VSALIDA           VARCHAR2 (800) := 'EXITO';
   CONTADOR          NUMBER := 0;
   VDIAS             NUMBER;
   VSERVICIO         VARCHAR2 (4);
   VCODIGO_DTL       VARCHAR2 (6);
   VDESCRP           VARCHAR2 (200);
   LV_TRANS_NUMBER   NUMBER := 0;
   NVAL_CAN          NUMBER := 0;
   VPAGADA           NUMBER := 0;
   VBANDERA          VARCHAR2 (3) := 'NO'; --esta bandera sirve para saber si entra o no en el cursor principal de tbraccd si no entra significa que no hay nada que cancelar
   VMMONTO           NUMBER;
   PCODE_ENV         VARCHAR2 (5);
   PPCODE2           VARCHAR2 (5);
   CUENTA_ENVIO      NUMBER := 0;
   VPAGO_TBRA        NUMBER := 0;
   V_CAMPUS          VARCHAR2 (4);
   VCODE_CURR        VARCHAR2 (8);
   VTRAN_DESC        NUMBER := 0;
   VTRAN_DESC2       NUMBER := 0;
   VPAGO_VALIDA      VARCHAR2 (20);
   VSALDO            NUMBER := 0;
   VPAGADA_V2        NUMBER := 0;
   VTBRAPPL_PAGADA   NUMBER := 0;
   VL_TIPO           VARCHAR2 (2);
   vprograma         VARCHAR2 (20);
   Vcursera          VARCHAR2 (1):= 'N';
   v_code_etiq       varchar2(4):= 'COUR';




/*
PPCODE      VARCHAR2(6):= 'NIVE';
PPIDM       NUMBER   := 280774;
no_serv      number  := 40654;
ppuser      varchar2(20) := 'WWW_USER_CAN';
vmateria    varchar2(14):= 'L2PD101';-----solo para dar de baja la materia de nivelacion
*/
--------esta validacion sirve para ver si ya esta o no cancelado la cartera antes del servicio---
-- se hace un ajuste para que las nivelaciones aunque tengan pagos parciales se puedan camcelar de modo automatico pasados los 3 dias glovicx 17.07.2024


BEGIN
   BEGIN
      SELECT NVL (ROWNUM, 0)
        INTO NVAL_CAN
        FROM TBRACCD TT
       WHERE     TT.TBRACCD_PIDM = PPIDM
             AND TT.TBRACCD_CROSSREF_NUMBER = NO_SERV
             AND TT.TBRACCD_DOCUMENT_NUMBER = 'WCANCE'
             and TBRACCD_CREATE_SOURCE      !=  'ACC_DIFER' ;
   EXCEPTION
      WHEN OTHERS
      THEN
         NVAL_CAN := 0;
   --  INSERT INTO TWPASOW(VALOR1, VALOR2, VALOR3 ) VALUES('P_CAN_SERV_ALL>>1',PPIDM, no_serv   ) ;

   END;

   IF NVAL_CAN > 0
   THEN ---si poralguna razon regresa 1 ya existe una cancelacion previa manda exito
      VSALIDA := 'EXITO';

      -- RETURN   VSALIDA;

      -----------------------SI ESTA CANCELADO EN LA CARTERA ES LOGICO QUE CANCELE EL SERVICIO ACTIVO------
      BEGIN
         UPDATE SVRSVPR V
            SET SVRSVPR_SRVS_CODE = 'CA',
                SVRSVPR_USER_ID = PPUSER,                         --'WWW_CAN',
                SVRSVPR_ACTIVITY_DATE = SYSDATE
          WHERE     1 = 1
                AND V.SVRSVPR_PIDM = PPIDM
                AND SVRSVPR_SRVS_CODE != 'PA' --CANELA TODO MENOS LO QUE YA ESTE PAGADO
                AND SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV;
      ----dbms_output.PUT_LINE('CANCELACION SOLO DEL SERVICIO:  '||PPIDM ||'-'|| NO_SERV );

      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      -- VSALIDA := SQLERRM;
      END;

      ----dbms_output.PUT_LINE('ya existe una cancelacion previa :: '||'-'||VSALIDA  );
      RETURN VSALIDA;                 ----AQUI REGRESA EXITO YA ESTA CANCELADA
   ELSE
      ----dbms_output.PUT_LINE('inicia la cancelacion :: '||'-'||PPCODE ||'-'|| PPIDM ||'-'|| no_serv );
      CUENTA_ENVIO := 0;                                   --vacia la variable



      FOR HI
         IN (  SELECT *
                 FROM TBRACCD TT
                WHERE     TT.TBRACCD_PIDM = PPIDM
                      AND TT.TBRACCD_CROSSREF_NUMBER = NO_SERV
                      AND (   TT.TBRACCD_DOCUMENT_NUMBER != 'WCANCE'
                           OR TT.TBRACCD_DOCUMENT_NUMBER IS NULL)
                      AND TBRACCD_DATA_ORIGIN IN
                             ('WEB-STUOSSR', 'PKG_SWTMDAC', 'Banner', 'ACC_DIFER')
                      AND NOT EXISTS
                                 (SELECT SVRSVPR_PROTOCOL_SEQ_NO
                                    FROM SVRSVPR V
                                   WHERE     1 = 1
                                         AND V.SVRSVPR_SRVS_CODE IN
                                                ('PA', 'CA')
                                         AND SVRSVPR_PROTOCOL_SEQ_NO =
                                                TT.TBRACCD_CROSSREF_NUMBER)
             ORDER BY 2 DESC)
      LOOP
         ----dbms_output.PUT_LINE('inicia la cancelacion LOOP :: '||'-'||PPCODE ||'-'|| PPIDM ||'-'|| no_serv||'-'||HI.TBRACCD_TRAN_NUMBER );
         VPAGO_VALIDA := '';                             ---INICIA LA VARIABLE
         VSALIDA := 'EXITO';

         --------PRIMERO VALIDAMOS QUE NO ESTE PAGADO POR QUE SE DA EL CASO QUE AUN PAGADO SE PUEDA CANCELAR---GLOVICX 04/08/2019
         --    BEGIN

         -----------------se cambia por la funcion de VIC ramirez
         SELECT upper(F_VALIDA_PAGO_ACCESORIO (PPIDM, HI.TBRACCD_TRAN_NUMBER))   AS RESULTADO
           INTO VPAGO_VALIDA
           FROM DUAL;

         VPAGO_VALIDA := REPLACE (VPAGO_VALIDA, 'N/A', 'AC');

         IF VPAGO_VALIDA IN ('N/A', NULL)
         THEN
            NULL;         ---se brinca este registro por que no es el servicio
         -- --dbms_output.PUT_LINE('brico regs '||VPAGO_VALIDA );
         ELSE
            --dbms_output.PUT_LINE('SALIDA FUNCIO VIC  '||VPAGO_VALIDA );
            
             IF UPPER(VPAGO_VALIDA) = 'PAGO PARCIAL' then  -----estos casos ya se pueden cancelar
             null;
              VPAGADA := 0;
              VPAGO_TBRA := 0;
               
              --dbms_output.PUT_LINE('este tiena pago parcials  '||VPAGO_VALIDA||'-'|| hi.tbraccd_balance||'-'||VPAGADA );
             end if; 
            
            
            BEGIN
               ------busca directa mapeada el no tran en tran paid
               SELECT DISTINCT NVL(TT.TBRACCD_TRAN_NUMBER_PAID,0)
                 INTO VPAGADA_V2
                 FROM TBRACCD TT
                WHERE     TT.TBRACCD_PIDM = PPIDM
               AND TT.TBRACCD_TRAN_NUMBER_PAID =  HI.TBRACCD_TRAN_NUMBER
                      AND TT.TBRACCD_CREATE_SOURCE != 'AD';
            EXCEPTION
               WHEN OTHERS
               THEN
                  VPAGADA_V2 := 0;
            ----dbms_output.put_line('Salida error en busca pago1  '|| vpagada_v2);
            END;

            BEGIN
               SELECT NVL(SUM (P.TBRAPPL_AMOUNT),0)
                 INTO VTBRAPPL_PAGADA
                 FROM TBRAPPL P, TBRACCD T
                WHERE     1 = 1
                      AND P.TBRAPPL_PIDM = T.TBRACCD_PIDM
                      AND P.TBRAPPL_CHG_TRAN_NUMBER = T.TBRACCD_TRAN_NUMBER
                      AND P.TBRAPPL_PIDM = PPIDM
                      AND T.TBRACCD_TRAN_NUMBER = HI.TBRACCD_TRAN_NUMBER
                      AND T.TBRACCD_CREATE_SOURCE != 'AD';
            EXCEPTION
               WHEN OTHERS
               THEN
                  VTBRAPPL_PAGADA := 0;
            ----dbms_output.put_line('Salida error en busca pago2:  '|| vtbrappl_pagada);
            --VSALIDA := SQLERRM;
            END;

            IF UPPER (VPAGO_VALIDA) IN ('PAGADO', 'PAGO PARCIAL') THEN
               VPAGO_TBRA := 1;

               ----SI ENTRA AQUI QUIERE DECIR LA FUNCION LA MARCO COMO PAGADA O PAGO PARCIAL
               BEGIN
                  UPDATE SVRSVPR V
                     SET SVRSVPR_SRVS_CODE =  DECODE (VPAGO_VALIDA, 'PAGADO', 'PA','PAGO PARCIAL','CA', 'AC'),
                         SVRSVPR_USER_ID = PPUSER,                --'WWW_CAN',
                         SVRSVPR_ACTIVITY_DATE = SYSDATE
                   WHERE     1 = 1
                         AND V.SVRSVPR_PIDM = PPIDM
                         AND SVRSVPR_SRVS_CODE <> 'PA' --CANELA TODO MENOS LO QUE YA ESTE PAGADO
                         AND SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV;
               ----dbms_output.PUT_LINE('CAMBIO ESTATUS A PAGADO SERVICIO:  '||PPIDM ||'-'|| NO_SERV );

               EXCEPTION WHEN OTHERS  THEN
                     NULL;
                     VSALIDA := SQLERRM;
               END;
               
                 VPAGO_TBRA := 0;
            --encontro pago o cancel la funcion de victor
            ----dbms_output.put_line('validacion de PAGO1: '||  PPIDM|| '-'||  HI.TBRACCD_TRAN_NUMBER||'-'||no_serv||'--'||VPAGO_VALIDA);

            ELSIF VPAGADA_V2 > 0  THEN
               VPAGO_TBRA := 1;
            ----dbms_output.put_line('validacion de PAGO2: '||  PPIDM|| '-'||  HI.TBRACCD_TRAN_NUMBER||'-'||no_serv);
            ELSIF VTBRAPPL_PAGADA > 0 THEN
               VPAGO_TBRA := 1;
            ----dbms_output.put_line('validacion de PAGO3: '||  PPIDM|| '-'||  HI.TBRACCD_TRAN_NUMBER||'-'||no_serv);
            ELSE
               VPAGO_TBRA := 0;
            ----dbms_output.PUT_LINE('validacion de NO__PAGO4: '||VPAGO_TBRA||'>>'||  PPIDM|| '-'||  HI.TBRACCD_TRAN_NUMBER||'-'||NO_SERV);

            END IF;

            ----dbms_output.PUT_LINE('ERRORF '||VSALIDA );

            --          EXCEPTION WHEN OTHERS THEN
            --                VPAGO_TBRA := 0;
            --                VSALIDA := SQLERRM;
            --                  --dbms_output.PUT_LINE('ERROR en validacion 5: '||  PPIDM|| '-'||  HI.TBRACCD_TRAN_NUMBER||'-'||NO_SERV);
            --           END;

            IF VPAGO_TBRA >= 1 THEN
               VSALIDA := 'PAGADO';         ---QUIERE DECIR QUE YA ESTA PAGADO
            ----dbms_output.PUT_LINE('ERRORK '||VSALIDA||'-'||VPAGO_TBRA );
            ELSE
               VPAGADA := 0;

               --------
               BEGIN
                  SELECT NVL (MAX (TBRACCD_TRAN_NUMBER), 0) + 1
                    INTO LV_TRANS_NUMBER
                    FROM TBRACCD
                   WHERE TBRACCD_PIDM = PPIDM;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VSALIDA := 'Error :' || SQLERRM;
                     LV_TRANS_NUMBER := 0;
               END;

               PPCODE2 := '';
               PCODE_ENV := '';

               ----dbms_output.PUT_LINE('ERRORH '||VSALIDA );
               ------------------------calcula el codigo de envio para ver si es internacional------------
               BEGIN
                  SELECT DISTINCT SVRSVPR_WSSO_CODE, SVRSVPR_CAMP_CODE
                    INTO PCODE_ENV, V_CAMPUS
                    FROM SVRSVPR
                   WHERE 1 = 1 AND SVRSVPR_PIDM = PPIDM --AND SVRSVPR_SRVS_CODE = 'AC'
                         AND SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV;

                  CUENTA_ENVIO := CUENTA_ENVIO + 1;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     PCODE_ENV := '';
               END;

               ------------------------------------------------------

               IF    HI.TBRACCD_DATA_ORIGIN = 'PKG_SWTMDAC'
                  OR HI.TBRACCD_CREATE_SOURCE = 'AD'
               THEN
                  ------des -aplica el pago ya que un descuento es como un pago -----

                  PKG_FINANZAS.P_DESAPLICA_PAGOS (PPIDM,HI.TBRACCD_TRAN_NUMBER);

                  /* SE AGREGA VARIABLE PARA IDENTIFICAR TIPO DE MOVIMIENTO  */

                  BEGIN
                     SELECT TBBDETC_DETAIL_CODE CODE_DTL,
                            TBBDETC_DESC DESCP,
                            TBBDETC_TYPE_IND
                       INTO VCODIGO_DTL, VDESCRP, VL_TIPO
                       FROM TBBDETC
                      WHERE     1 = 1
                            AND TBBDETC_TYPE_IND = 'C'
                            AND TBBDETC_DETAIL_CODE IN
                                      SUBSTR (F_GETSPRIDENID (PPIDM), 1, 2)
                                   || 'V2';
                  ---CODIGO DE CANCELACION DE DESCUENTOS ME LO PASO REZA;--nuevo CODIGO LO PASO YAMILET 12/07/022"V2"
                  --dbms_output.PUT_LINE(' ENTRO A DESAPLICAR EL DESCUENTO(PKG_SWTMDAC) ::'||vcodigo_dtl||'--'|| HI.TBRACCD_TRAN_NUMBER );


                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  ----dbms_output.PUT_LINE(' error no se encontro code de detalle ::'||CONTADOR );
                  END;

                  VTRAN_DESC := HI.TBRACCD_TRAN_NUMBER; --aqui guarda en la variable en num. de trans del descuento  este se borra
                  VTRAN_DESC2 := HI.TBRACCD_TRAN_NUMBER; --aqui guarda en la variable en num. de trans del descuentoeste se conserva
                  VMMONTO := (HI.TBRACCD_AMOUNT);
               ----dbms_output.PUT_LINE(' SI HAY  code de Descuento ::'||vtran_desc );
               -------aqui hace la validacion de si esta pagada en tbraappl--

               ----dbms_output.put_line('transaccion descuento AD no es pagada ES  DESCUENTO:  '|| VPAGADA  );

               ELSE
               ----dbms_output.put_line('transaccion No hay desc:  '|| VPAGADA  );
                  begin
                    select  SVRSVAD_ADDL_DATA_CDE
                    into vprograma
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PPCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '1';-- busca el programa


                  exception when others then
                   vprograma := '';

                  end;



                  BEGIN
                     -------------aqui hace la validacion y cambio de codigo de envio internacional----------
                     IF PCODE_ENV = '01UF' AND CUENTA_ENVIO = 1
                     THEN
                        PPCODE2 := PCODE_ENV;
                     ----dbms_output.put_line('entra code envio  inter  '|| PPCODE2 || '-**-'|| cuenta_envio);

                     ELSE
                        NULL;
                        PPCODE2 := PPCODE;
                     ----dbms_output.put_line('NNNOOOO  entra code envio  inter  '|| PPCODE2 || '-**-'|| cuenta_envio );
                     END IF;

                     --------------------------------------------------------

                     /* SE AGREGA VARIABLE PARA IDENTIFICAR TIPO DE MOVIMIENTO  */

                     SELECT DISTINCT
                            TBBDETC_DETAIL_CODE CODE_DTL,
                            TBBDETC_DESC DESCP,
                            TBBDETC_TYPE_IND
                       INTO VCODIGO_DTL, VDESCRP, VL_TIPO
                       FROM TBBDETC T, SZTCCAN ZC
                      WHERE     1 = 1
                            AND TBBDETC_TYPE_IND = 'P'
                            AND TBBDETC_DCAT_CODE IN ('CAN', 'DSC')
                            AND T.TBBDETC_TAXT_CODE  = decode (T.TBBDETC_TAXT_CODE,'GN',T.TBBDETC_TAXT_CODE, substr(vprograma,4,2))
                            AND SUBSTR (T.TBBDETC_DETAIL_CODE, 3, 2) =
                                   SUBSTR (ZC.SZTCCAN_CODE, 3, 2)
                            AND ZC.SZTCCAN_CODE_SERV = PPCODE2
                            AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2) =
                                   SUBSTR (F_GETSPRIDENID (PPIDM), 1, 2);


                     VMMONTO := (HI.TBRACCD_AMOUNT * -1);
                  EXCEPTION  WHEN OTHERS  THEN
                      --dbms_output.PUT_LINE(' error no se encontro code de detalleXX1  ::'||VMMONTO );
                       
                       
                       begin
                          SELECT DISTINCT
                                TBBDETC_DETAIL_CODE CODE_DTL,
                                TBBDETC_DESC DESCP,
                                TBBDETC_TYPE_IND
                           INTO VCODIGO_DTL, VDESCRP, VL_TIPO
                           FROM TBBDETC T, SZTCCAN ZC
                          WHERE     1 = 1
                                AND TBBDETC_TYPE_IND = 'P'
                            AND TBBDETC_DCAT_CODE IN ('CAN', 'DSC')
                         --   AND T.TBBDETC_TAXT_CODE  = NVL(substr(vprograma,4,2), T.TBBDETC_TAXT_CODE)
                            AND SUBSTR (T.TBBDETC_DETAIL_CODE, 3, 2) =  SUBSTR (ZC.SZTCCAN_CODE, 3, 2)
                            AND ZC.SZTCCAN_CODE_SERV = PPCODE2
                            AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2) = SUBSTR (F_GETSPRIDENID (PPIDM), 1, 2);
                        exception when others then

                            VCODIGO_DTL := '01B4';
                            VSALIDA := SQLERRM;
                            ----dbms_output.PUT_LINE(' error no se encontro code de detalle2 ::'||VSALIDA );
                        end;

                  END;

                  --dbms_output.PUT_LINE(' al salir de code de detalle3  nuevo monto para pago parcial::'||VCODIGO_DTL|| VPAGO_VALIDA );
                  
                    IF PPCODE = 'NIVE' AND VPAGO_VALIDA IN ( 'PAGO PARCIAL' , 'ACTIVO')  THEN 
                     
                      --VMMONTO :=  ((HI.TBRACCD_AMOUNT  - HI.TBRACCD_BALANCE))* -1 ;
                       VMMONTO := (HI.TBRACCD_AMOUNT * -1);
                       --dbms_output.PUT_LINE(' MONTO X PAGO PARCIAL ::'|| VMMONTO  );
                       
                    ELSE
                  --AQUI NO ES DESCUENTO Y LIMPIA LA VARIABLE
                  VMMONTO := (HI.TBRACCD_AMOUNT * -1);
                  VTRAN_DESC := 0;
                      
                    END IF;  
                    
               -- --dbms_output.PUT_LINE(' error no se encontroDESCUENTO  ::'|| vtran_desc || '---'|| hi.TBRACCD_TRAN_NUMBER  );
               END IF;

               --------valida tbrappl  PARA VER SI YA ESTA PAGADO O NO EL SERVICIO
               -- --dbms_output.PUT_LINE('REGS--en VALIDA SI EXITE UN PAGOOOXX2 -'||'-'||Jump.pidm||'-'||Jump.seq_no||'-'|| jump.code||'-'||VPAGO_TBRA||'-'||HI.TBRACCD_TRAN_NUMBER ||'-'|| VPAGADA ||'--'||vtran_desc );

               BEGIN
                  SELECT ZSTPARA_PARAM_VALOR
                    INTO VCODE_CURR
                    FROM ZSTPARA
                   WHERE     ZSTPARA_MAPA_ID = 'CAMPUS_AUTOSERV'
                         AND ZSTPARA_PARAM_ID = V_CAMPUS; ---ESTE ES EL CAMPUS
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VCODE_CURR := 'Error :' || SQLERRM;
                     -- vigencia := 0;
                     VSALIDA := 'Error en codigo de moneda :' || SQLERRM;
               END;

               ----dbms_output.PUT_LINE('ERRORC '||VPAGADA|| '-'||VMMONTO  );
                --valida si es cursera coursera glovicx 04/10/2021
                 begin
                    select 'Y'
                       INTO  Vcursera
                     From ZSTPARA
                       where 1=1
                        AND ZSTPARA_MAPA_ID = 'CODI_NIVE_UNICA'
                        and ZSTPARA_PARAM_DESC like('COURSERA%')
                        and ZSTPARA_PARAM_ID = PPCODE;


                 exception when others then
                 Vcursera := 'N';
                 end;




                IF  Vcursera = 'Y'    THEN
                        --ejecuta la funcion de CHUY para cancelar coursera glovicx 04/10/2021
                   VSALIDA := BANINST1.PKG_SENIOR.F_CANCELA_COUR ( PPIDM );
                   ----dbms_output.put_line(' cancela la F_CHUY  '|| VSALIDA );
                   ----tambien tiene que cancelar o quitar la etiqueta de goradid
                    PKG_FREEMIUM.quita_etiqueta(ppidm, v_code_etiq);
                   ----dbms_output.put_line(' cancela la ETIQUETA  '|| VSALIDA );
                end if;

                IF PPCODE = 'DIPD' then  -- accesorio costo cero entra sin validaciones glovicx 20.01.2023
                   VPAGADA  := 0;
                   VSALIDA   := 'EXITO';
                  --dbms_output.put_line(' entra dipd >>  '|| VSALIDA );
                end if;


               ---------------------------------------
               IF VPAGADA = 0
               THEN
                  --------------------------------------------inserta la cancelacion de  tbraccd---
                  BEGIN
                     INSERT INTO TBRACCD (TBRACCD_PIDM,
                                          TBRACCD_TERM_CODE,
                                          TBRACCD_DETAIL_CODE,
                                          TBRACCD_USER,
                                          TBRACCD_ENTRY_DATE,
                                          TBRACCD_AMOUNT,
                                          TBRACCD_BALANCE,
                                          TBRACCD_EFFECTIVE_DATE,
                                          TBRACCD_DESC,
                                          TBRACCD_CROSSREF_NUMBER,
                                          TBRACCD_SRCE_CODE,
                                          TBRACCD_ACCT_FEED_IND,
                                          TBRACCD_SESSION_NUMBER,
                                          TBRACCD_DATA_ORIGIN,
                                          TBRACCD_TRAN_NUMBER,
                                          TBRACCD_ACTIVITY_DATE,
                                          TBRACCD_MERCHANT_ID,
                                          TBRACCD_TRANS_DATE,
                                          TBRACCD_DOCUMENT_NUMBER,
                                          TBRACCD_FEED_DATE,
                                          TBRACCD_STSP_KEY_SEQUENCE,
                                          TBRACCD_PERIOD,
                                          TBRACCD_CURR_CODE,
                                          TBRACCD_TRAN_NUMBER_PAID,
                                          TBRACCD_RECEIPT_NUMBER)
                          VALUES (PPIDM,
                                  HI.TBRACCD_TERM_CODE,
                                  VCODIGO_DTL,                    --VCODE_DTL,
                                  PPUSER,                        -- 'WWW_CAN',
                                  SYSDATE,
                                  HI.TBRACCD_AMOUNT,
                                  VMMONTO,          ---(HI.TBRACCD_AMOUNT*-1),
                                  (SYSDATE),
                                  VDESCRP,
                                  NO_SERV,
                                  'T',
                                  'Y',
                                  0,
                                  'WEB-BAJA_JOB',
                                  LV_TRANS_NUMBER,
                                  SYSDATE,
                                  NULL,
                                  SYSDATE,
                                  LV_TRANS_NUMBER,
                                  HI.TBRACCD_FEED_DATE,
                                  HI.TBRACCD_STSP_KEY_SEQUENCE,
                                  HI.TBRACCD_PERIOD,
                                  VCODE_CURR                           --'MXN'
                                            ,
                                  HI.TBRACCD_TRAN_NUMBER,
                                  HI.TBRACCD_RECEIPT_NUMBER);

                     -----dbms_output.PUT_LINE('inserta en tbraccd ::'||jump.pidm||'-'||lv_trans_number||'--'||jump.seq_no||'---'|| sql%rowcount );
                     CONTADOR := CONTADOR + SQL%ROWCOUNT;
                  EXCEPTION  WHEN OTHERS  THEN
                        NULL;
                        VSALIDA := SQLERRM;
                  ----dbms_output.PUT_LINE('error al insertar tbraccd code cancelacion::'||VSALIDA );
                  END;

                  /* SE AGREGA UPDATE PARA EL DESCUENTO ASOCIADO AL ACCESORIO Y LIBERAR   ESTO LO LIBERO  REZA*/

                  IF VL_TIPO = 'P'
                  THEN
                     UPDATE TBRACCD
                        SET TBRACCD_TRAN_NUMBER_PAID = NULL
                      WHERE     TBRACCD_PIDM = PPIDM
                            AND TBRACCD_TRAN_NUMBER_PAID =
                                   HI.TBRACCD_TRAN_NUMBER
                            AND TBRACCD_TRAN_NUMBER != LV_TRANS_NUMBER;
                  END IF;

                  IF VPAGADA = 0 AND VL_TIPO = 'P'
                  THEN
                     BEGIN
                        UPDATE TBRACCD
                           SET TBRACCD_DOCUMENT_NUMBER = 'WCANCE',
                               TBRACCD_TRAN_NUMBER_PAID = NULL
                         WHERE     TBRACCD_PIDM = PPIDM
                               AND TBRACCD_TRAN_NUMBER =
                                      HI.TBRACCD_TRAN_NUMBER
                               AND TBRACCD_CROSSREF_NUMBER = NO_SERV;

                        CONTADOR := CONTADOR + SQL%ROWCOUNT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VSALIDA := SQLERRM;
                     END;

                     BEGIN
                        UPDATE SVRSVPR V
                           SET SVRSVPR_SRVS_CODE = 'CA',
                               SVRSVPR_USER_ID = PPUSER,          --'WWW_CAN',
                               SVRSVPR_ACTIVITY_DATE = SYSDATE
                         WHERE     1 = 1
                               AND V.SVRSVPR_PIDM = PPIDM
                               AND SVRSVPR_SRVS_CODE != 'PA' --CANELA TODO MENOS LO QUE YA ESTE PAGADO
                               AND SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV;
                     ----dbms_output.PUT_LINE('CACELACION FINAL DEL SERVICIO Y CARTERA'||PPIDM ||'-'|| NO_SERV );

                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           NULL;
                           VSALIDA := SQLERRM;
                     END;
                  END IF;
               END IF;

               VBANDERA := 'YES';
            ----dbms_output.PUT_LINE('NUMERO DE cancelaciones  insertados::'||CONTADOR );
            ---   COMMIT;

            END IF;   
                                           --IF DE SI YA ESTA PAGADO
         END IF;                                   --SI LA FUNCION REGRESA N/A
      END LOOP;                                          --END LOOP DE TBRACCD

      ----dbms_output.PUT_LINE('salidax '||VSALIDA );

      --
      IF VSALIDA = 'EXITO' AND VPAGADA = 0
      THEN
         RETURN (VSALIDA);

         ----dbms_output.PUT_LINE('salida_DE REGS BORRADOS con exito:  '||VSALIDA );
         COMMIT;
      ELSE
         ROLLBACK;

         --  INSERt INTO TWPASOW(VALOR1, VALOR2, VALOR3,VALOR4, valor5)
         --        VALUES('ESTOY EN TRABCCD vsalida FRACSO2 tbra ', VSALIDA, PPIDM, PPcode,lv_trans_number  );
         --     ------como es muy problabe que ya haya insertado el descuento en la pasada anterior hay que borrar el desc.
         --PPCODE VARCHAR2, PPIDM NUMBER , no_serv number,
         DELETE TBRACCD
          WHERE     TBRACCD_PIDM = PPIDM
                AND TBRACCD_TRAN_NUMBER = LV_TRANS_NUMBER ---ESTE ES EL ÚLTIMO REGS QUE GUARDO
                AND TBRACCD_CROSSREF_NUMBER = NO_SERV;

         COMMIT;

         -----------------------------
         VSALIDA := 'PAGO_PARCIAL';
         RETURN (VSALIDA);
      -- --dbms_output.PUT_LINE('ERRORww '||VSALIDA );


      END IF;                                               --IF EXITO O ERROR
   END IF;                                                 -- IF GRAL  INICIAL
   
EXCEPTION WHEN OTHERS THEN

      VSALIDA := 'Error :' || SQLERRM;
      ROLLBACK;
      RETURN VSALIDA;
--  --dbms_output.PUT_LINE('Error general--  '|| VSALIDA);

END P_CAN_SERV_ALL;




------------------------SE INSERTA ESTAS NUEVAS FUNCIONALIDADES Y VALIDACIONES GLOVICX 12/07/2019------
FUNCTION  FCAMPUS (PPIDM NUMBER, PPROGRAM  VARCHAR2) RETURN vARCHAR2  IS

vcampus  varchar2(10);

BEGIN
     SELECT distinct SO.SORLCUR_CAMP_CODE
        INTO vcampus
       FROM sorlcur so
         where SO.SORLCUR_PIDM     = ppidm
           and SO.SORLCUR_PROGRAM  = PPROGRAM
            AND SO.SORLCUR_LMOD_CODE  = 'LEARNER'
           ;

return vcampus;

exception when others then
return sqlerrm;

END FCAMPUS;

FUNCTION  FNIVEL (PPIDM NUMBER, PPROGRAM  VARCHAR2) RETURN vARCHAR2  IS

vnivel  varchar2(10);

BEGIN
     SELECT distinct SO.SORLCUR_LEVL_CODE
        INTO vnivel
       FROM sorlcur so
         where SO.SORLCUR_PIDM       = ppidm
           and SO.SORLCUR_PROGRAM    = PPROGRAM
           AND SO.SORLCUR_LMOD_CODE  = 'LEARNER'
           ;

return vnivel;

exception when others then
return sqlerrm;

END FNIVEL;

FUNCTION  FPERIODO (PPIDM NUMBER, PPROGRAM  VARCHAR2) RETURN vARCHAR2  IS

vperiodo  varchar2(12);

BEGIN
     SELECT distinct SO.SORLCUR_TERM_CODE
        INTO vperiodo
       FROM sorlcur so
         where SO.SORLCUR_PIDM       = ppidm
           and SO.SORLCUR_PROGRAM    = PPROGRAM
           AND SO.SORLCUR_LMOD_CODE  = 'LEARNER'
            and SO.SORLCUR_TERM_CODE = ( select  max(SO2.SORLCUR_TERM_CODE) from sorlcur so2
                                                where  SO2.SORLCUR_PIDM       = ppidm
                                                   and SO2.SORLCUR_PROGRAM    = PPROGRAM
                                                   AND SO2.SORLCUR_LMOD_CODE  = 'LEARNER') ;

return vperiodo;

exception when others then
return sqlerrm;

END FPERIODO;

FUNCTION F_DATA_MATPRO (PSEQ_NO NUMBER  ) Return PKG_SERV_SIU.matprog_type
IS
 CUR_MATPROG BANINST1.PKG_SERV_SIU.matprog_type;


BEGIN

 open CUR_MATPROG for select (
                             select SVRSVAD_ADDL_DATA_CDE
                              FROM SVRSVAD h
                              where 1=1
                                and h.SVRSVAD_PROTOCOL_SEQ_NO = PSEQ_NO
                               -- and substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1 ) = nvl(:pmateria,substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1 )  )
                                 and H.SVRSVAD_ADDL_DATA_SEQ = 2
                              ) as materia,
                            (select SVRSVAD_ADDL_DATA_CDE
                             FROM SVRSVAD h
                              where 1=1
                                and h.SVRSVAD_PROTOCOL_SEQ_NO = PSEQ_NO
                                --and h.SVRSVAD_ADDL_DATA_CDE   =    :pprograma
                                and H.SVRSVAD_ADDL_DATA_SEQ = 1
                                ) as programa
                             from dual;

  return CUR_MATPROG;
    Exception
            When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.CUR_MATPROG: ' || sqlerrm;
           return CUR_MATPROG;
END  F_DATA_MATPRO;

FUNCTION F_VALIDA_SERVICIO ( PPIDM NUMBER, PPCODE VARCHAR2) RETURN VARCHAR2 IS

VSALIDA  VARCHAR2(100);
VCUENTA  NUMBER:=0;
--------------------esta funcion  valida si ya existe una solicitud antes creada del mismo tipo
--------glovicx 16/07/2019---
--se agrega el parametrizador para los servicios que se pueden hacer mas de una vez
-- se agrega la funcionalidad de COLX NIVEL   glovicx 29/06/021
BEGIN

  ----dbms_output.put_line(' f_validaser 1 ');


FOR JUMP IN ( SELECT (ZSTPARA_PARAM_VALOR) CODIGO  FROM SATURN.ZSTPARA
                            WHERE ZSTPARA_MAPA_ID = 'MAS_SOLIC_1SS'
                             AND ZSTPARA_PARAM_VALOR  = PPCODE )  LOOP
  VSALIDA :=  ('EXITO');

 END LOOP;

    ----dbms_output.put_line(' f_validaser 2 ');

 IF   VSALIDA  = 'EXITO'  THEN
    ----dbms_output.put_line(' f_validaser 3 ');
   RETURN (VSALIDA);

 ELSIF   PPCODE = 'COLF'  THEN   -- SE AGREGA ESTA VALIDACIÓN PARA COLF PARA QUE DEJE PASAR TODOS LOS NIVELES GLOVICX 07/06/021
     ----dbms_output.put_line(' f_validaser 4 ');
     VSALIDA :=  ('EXITO');
     RETURN (VSALIDA);


 ELSE
   ----dbms_output.put_line(' f_validaser 5 ');
     BEGIN
        select COUNT(*)
           INTO VCUENTA
         from svrsvpr v
            where 1=1
            AND SVRSVPR_SRVC_CODE NOT IN (SELECT (ZSTPARA_PARAM_VALOR) FROM SATURN.ZSTPARA
                                                    WHERE ZSTPARA_MAPA_ID = 'SERVICIO_MULTIP')
               AND v.SVRSVPR_PIDM   = PPIDM
               AND v.SVRSVPR_SRVS_CODE IN  ('AC')
               AND TRUNC(V.SVRSVPR_ACTIVITY_DATE) >= SYSDATE-3
               and V.SVRSVPR_SRVC_CODE  = PPCODE   ;   --- se le agrega esta variable para ajustar los codigos glovicx 29/06/021 se libera con COLF X NIVEL


         -- --dbms_output.put_line(' f_validaser 6 '|| VCUENTA );
     EXCEPTION WHEN OTHERS THEN
         VCUENTA:= 0;
     END;


    ----dbms_output.put_line(' f_validaser 7 '||  VSALIDA );


       IF VCUENTA = 0  THEN
            VSALIDA := 'EXITO';
         ELSE
           VSALIDA := 'solicitud existente, favor de revisar tu historial de solicitudes para realizar tu pago';
        END IF;




      RETURN (VSALIDA);

  END IF;

 Exception
         When others  then
  RETURN SQLERRM;


END F_VALIDA_SERVICIO ;

-----------------------------------------------------------------
PROCEDURE  P_inserta_horario ( ppidm number,  pcode varchar2, pperiodo varchar2, pcampus varchar, PSEQ_NO NUMBER, pregreso OUT varchar2 )
IS
-----se debe insertar siempre el horario del alumno para la nivelacio. si paga en linea ya esta cagado el horario
-- pero si no paga y se cancela entonces se borra el horario ..
--glovicx 27/06/2019-----
-- se agrega modificación para nivelacion bachillerato glovicx 2.5.024


schd        VARCHAR2(10):= NULL;
title       VARCHAR2(90):= NULL;
credit       NUMBER;  -- VARCHAR2(10):= NULL;
gmod        VARCHAR2(40):=NULL;
f_inicio    VARCHAR2(16):=NULL;
f_fin       VARCHAR2(16):=NULL;
sem         VARCHAR2(10):=NULL;
crn         VARCHAR2(10):= NULL;
pidm_prof   VARCHAR2(14):= '019852882';  -------QUITAR DESPUES DE LAS PRUEBAS
credit_bill  NUMBER  ; --VARCHAR2(10):= NULL;
vl_exite_prof NUMBER:=0;
V_SEQ_NO     NUMBER:=0;
vpparte      VARCHAR2(5);
VMATERIA     VARCHAR2(14);
Vnivel       VARCHAR2(4);
Vgrupo       VARCHAR2(3):='01';
Vsubj        VARCHAR2(5);
Vcrse        VARCHAR2(5);
conta_ptrm   NUMBER:=0;
Vstudy        NUMBER:=0;
VPROGRAMA     VARCHAR2(14);
pidm_prof2    number:=0;
cssrmet      number:=0;
csirasgn     number:=0;
VSALIDA      VARCHAR2(5000):='EXITO';
VNSFRST      NUMBER:=0;
vno_orden     number:=0;
NO_ORDEN_OLD   NUMBER:=0;
VFINI2          VARCHAR2(14);
VFFIN2          VARCHAR2(14);
Vperiodo       VARCHAR2(20);


begin

IF PCODE IN ('NIVE','NABA') THEN
null;


-----------------------NSERTA TABLA DE PASO PARA PRUEBA S----------------------

-- --dbms_output.put_line('INICIO :1::  '||Ppidm ||'-'|| PSEQ_NO||'-'||PPERIODO ||'-'||PCODE );
    schd := null;
    title := null;
    credit := null;
    gmod :=null;
    f_inicio :=null;
    f_fin :=null;
    sem :=null;
    crn := null;
    pidm_prof := null;
    vl_exite_prof :=0;
    vpparte     := '';
       --   INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7)
        --  VALUES ('p_INSERTA_HORARIO_PARAM DE INICIO', ppidm ,  pcode , pperiodo , pcampus , PSEQ_NO, SYSDATE  );COMMIT;
                           BEGIN
                          select V.SVRSVPR_PROTOCOL_SEQ_NO
                                 , case  when INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1) > 0 then
                                      --SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1)
                                      SVRSVAD_ADDL_DATA_CDE
                                       else
                                      --SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10)-1 )
                                      SVRSVAD_ADDL_DATA_CDE
                                  end as materia
                                INTO V_SEQ_NO, vmateria
                             from svrsvpr v,SVRSVAD VA
                                    where SVRSVPR_SRVC_CODE = pcode
                                       AND  SVRSVPR_PIDM   = ppidm
                                        AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PSEQ_NO
                                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                       and va.SVRSVAD_ADDL_DATA_SEQ in ( 2) ; ------el valor 2 es para la materia
                         EXCEPTION WHEN OTHERS THEN
                           VMATERIA :='';
                           V_SEQ_NO := 0;
                           VSALIDA  := SQLERRM;
                         END;

                          ----dbms_output.put_line('RECUPERA LA MATERIA DE NIVE::'|| vmateria);
                             --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('PASOWWW_SIU_MATERIA ',Ppidm, PSEQ_NO,vmateria, SUBSTR(vl_error,1,100), sysdate);

                          BEGIN
                            select V.SVRSVPR_PROTOCOL_SEQ_NO
                                 , case  when INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1) > 0 then
                                      SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1)
                                       else
                                      SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10)-1 )
                                  end as PPARTE
                                 INTO V_SEQ_NO, vpparte
                               from svrsvpr v,SVRSVAD VA
                                    where SVRSVPR_SRVC_CODE = pcode
                                       AND  SVRSVPR_PIDM   = ppidm
                                        AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PSEQ_NO
                                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                       and va.SVRSVAD_ADDL_DATA_SEQ in (7) ; ------el valor 2 es para la parte de periodo
                         EXCEPTION WHEN OTHERS THEN
                           VPPARTE :='';
                           V_SEQ_NO := 0;
                           VSALIDA  := SQLERRM;
                         END;
                          ----dbms_output.put_line('RECUPERA LA PARTE PERIODO DE NIVE::'|| vpparte);
                               --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('PASOWWW_SIU_PPARTEP ',Ppidm, PSEQ_NO,vpparte, SUBSTR(vl_error,1,100),sysdate);

                        BEGIN
                            select V.SVRSVPR_PROTOCOL_SEQ_NO ,
                               SVRSVAD_ADDL_DATA_CDE  PROG
                                 INTO V_SEQ_NO, VPROGRAMA
                               from svrsvpr v,SVRSVAD VA
                                    where SVRSVPR_SRVC_CODE = pcode
                                       AND  SVRSVPR_PIDM   = ppidm
                                       AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PSEQ_NO
                                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                       and va.SVRSVAD_ADDL_DATA_SEQ in ( 1) ; ------el valor1 es programa
                         EXCEPTION WHEN OTHERS THEN
                           VPROGRAMA :='';
                           V_SEQ_NO := 0;
                           VSALIDA  := SQLERRM;
                         END;
                   -------como ya no hay periodo ahora sacamos de la parte del periodo selecionado
                   ------obtenemos el rango de fechas ini y fin
         begin
                select substr(rango,1, instr(rango,'-AL-',1 )-1)as fecha_ini
                        ,substr(rango,instr(rango,'-AL-',1 )+4)as fecha_fin
                        INTO VFINI2, VFFIN2
                from (
                select   --substr(SVRSVAD_ADDL_DATA_DESC,33  )  rango
                      SVRSVAD_ADDL_DATA_DESC  rango
                         from svrsvpr v,SVRSVAD VA
                            where SVRSVPR_SRVC_CODE = pcode
                            AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQ_NO
                              AND  SVRSVPR_PIDM    = ppidm
                               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                               and va.SVRSVAD_ADDL_DATA_SEQ = '7' --- ES EL MISMO DEL PARTE DE PERIODO
                               ) ;

          EXCEPTION WHEN OTHERS  THEN
            VFINI2:= TRUNC(SYSDATE);
            VFFIN2 := TRUNC(SYSDATE)+7;
          END;
         -------CON LA FECHAS BUSCAMOS EL PERIODO Y LO CALCULAMOS


            Begin

             select SOBPTRM_TERM_CODE
                into Vperiodo
                from sobptrm
                where 1=1
                and  sobptrm_ptrm_code   = TRIM(vpparte)
                AND TRUNC(SOBPTRM_START_DATE)  >=  TO_DATE(TRIM(VFINI2), 'DD/MM/YYYY')
                AND TRUNC(SOBPTRM_END_DATE)    <=  TO_DATE(TRIM(VFFIN2), 'DD/MM/YYYY')
                and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                ;

            Exception
            When Others then
            vl_error :=  sqlerrm;
--            INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 , valor7)
--            VALUES ('INSRT_HORARIO_periodo_ERROORR22:: ',Ppidm, PSEQ_NO,Vperiodo||' *-* '||VPparte, VFINI2, vl_error, VFFIN2);
--            commit;
            VSALIDA  := SQLERRM;
            End;

--         INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 , valor7)
--            VALUES ('INSRT_HORARIO_periodo_ooookkkkk:: ',Ppidm, PSEQ_NO,Vperiodo||' *-* '||VPparte, VFINI2, vl_error, VFFIN2);
--            commit;

                      begin
                       select SCBCRSE_SUBJ_CODE, SCBCRSE_CRSE_NUMB
                         INTO VSUBJ, VCRSE
                        from scbcrse
                         where SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB = vmateria;
                         ----dbms_output.put_line('RECUPERA el SUBJ__CRSE::'|| VSUBJ||'-'||VCRSE);
                     exception when others then
--                       VSUBJ :=null;
  --                     VCRSE :=null;
  -----dbms_output.put_line('RECUPERA el SUBJ__CRSE:antes:'|| VSUBJ||'-'||VCRSE);
                        if  length(vmateria) = 9  then
                             VSUBJ :=SUBSTR(vmateria,1,4);
                             VCRSE :=SUBSTR(vmateria,5,5);

                       elsif  length(vmateria) = 8  then
                             VSUBJ :=SUBSTR(vmateria,1,4);
                             VCRSE :=SUBSTR(vmateria,5,4);

                            ELSE
                               VSUBJ :=SUBSTR(vmateria,1,3);
                               VCRSE :=SUBSTR(vmateria,4,4);
                       end if;

                      -- VSALIDA  := SQLERRM;
                       ----dbms_output.put_line('RECUPERA el SUBJ__CRSE222::'|| VSUBJ||'-'||VCRSE);
                     end;

                           Begin
                             select scrschd_schd_code, scbcrse_title, scbcrse_credit_hr_low, SCBCRSE_BILL_HR_LOW
                                into schd, title, credit, credit_bill
                                 from scbcrse, scrschd
                                where scbcrse_subj_code||scbcrse_crse_numb = TRIM(vmateria)
                                 and     scbcrse_eff_term='000000'
                                 and     SCBCRSE_CSTA_CODE  = 'A'
                                 and     scrschd_subj_code=scbcrse_subj_code
                                 and     scrschd_crse_numb=scbcrse_crse_numb
                                 and     scrschd_eff_term=scbcrse_eff_term;
                           Exception
                            When Others then
                                  schd := null;
                                  title := null;
                                  credit := null;
                                  credit_bill :=null;
                                   ----dbms_output.PUT_LINE('EEEERRRROOOR DEL CREDITOS Y MAS :: '|| VSUBJ||'-'||VCRSE);
                                   VSALIDA  := SQLERRM;
                           End;

                       -----dbms_output.PUT_LINE('SALIDA DEL CREDITOS Y MAS :: '|| schd||'-'|| title||'-'||credit||'-'||credit_bill );
                        --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_CREDITOS ',Ppidm, PSEQ_NO,schd||'-'||title, SUBSTR(vl_error,1,100), sysdate);
                            begin
                                select scrgmod_gmod_code
                                      into gmod
                                from scrgmod
                                where scrgmod_subj_code||scrgmod_crse_numb=VMATERIA
                                and     scrgmod_default_ind='D';
                            exception when others then
                                gmod:='1';
                               -- VSALIDA  := SQLERRM;
                            end;
                              ----dbms_output.PUT_LINE('SALIDA D GMOD CODE :: '|| gmod );
                      BEGIN

                       SELECT DISTINCT SMRPRLE_LEVL_CODE
                       INTO VNIVEL
                       FROM SMRPRLE
                       WHERE SMRPRLE_PROGRAM = VPROGRAMA;

                      EXCEPTION WHEN OTHERS THEN
                      VNIVEL :='';
                      VSALIDA  := SQLERRM;
                      END;
                         ----dbms_output.PUT_LINE('SALIDA D NIVEL :: '|| VNIVEL );
                        ---------------------aqui va la validacion de si ya existe el horario entoces hace la compactacion de grupos o no?---
                         begin                  ---- validacion UNO ver si existe el CRN creado para esa materia,parteperiod,periodo en gral
                            SELECT SSBSECT_CRN
                            into CRN
                                FROM SSBSECT
                                WHERE 1=1
                                --and SSBSECT_CRN = 'A9'
                                AND   SSBSECT_TERM_CODE = vPERIODO
                                and   SSBSECT_PTRM_CODE = vpparte
                                and   SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB = vmateria ;

                                null;
                         exception when others then
                         null;
                         crn := null;

                         --VSALIDA  := SQLERRM;
                         end;

                    conta_ptrm :=0;
                   ----dbms_output.put_line('salida 21  '||PPIDM ||'-'|| VPROGRAMA );
                        Begin
                             select count(*)
                                into conta_ptrm
                             from sfbetrm
                             where sfbetrm_term_code=vPERIODO
                             and     sfbetrm_pidm=PPIDM;
                        Exception
                            When Others then
                              conta_ptrm := 0;
                            --  VSALIDA  := SQLERRM;
                        End;


                         if conta_ptrm =0 then
                                Begin
                                        insert into sfbetrm values(vPERIODO, PPIDM, 'EL', sysdate, 99.99, 'Y', null, sysdate, sysdate, null,null,null,null,'WWW_SIU', null,'WWW_SIU', null, 0,null,null, null,null,user,PSEQ_NO);
                                Exception
                                When Others then
                                    VSALIDA  := ('Se presento un error al insertar en la tabla sfbetrm ' || sqlerrm);
                                 --  insert into twpasow(valor1,valor2,valor3,valor4, valor5) values('ERROR_inserta_sfbetrm::1: ',pidm_prof2,PPERIODO,crn, sysdate );commit;
                                End;
                         end if;

                         ------------------------  primer caso el CRN ya existe es decir ya se abrio un grupo para ese periodo, parte de per y materia
                         ---------------hay que utilizar ese grupo para todos los alumnos que pidan nivelacion con las mismas caracteristicas.
                         ----------------solo hay que crear el horario en sfrstrc  con el estatus de la materia RE.
                IF CRN is not null  then
                  ----------------------------ahora valida si esta esta insertado el regs para ese alumno pero tiene estatus dd
                  ----------------------------si es correcto entonces solo cambia el estatus a RE....si, no lo inserta
                            BEGIN
                                  SELECT COUNT(1)
                                    INTO VNSFRST
                                    FROM SFRSTCR  F
                                    WHERE  F.SFRSTCR_CRN     = CRN
                                    AND F.SFRSTCR_TERM_CODE  = vPERIODO
                                    AND F.SFRSTCR_PIDM       = PPIDM
                                    and F.SFRSTCR_PTRM_CODE  = vpparte ;

                             EXCEPTION WHEN OTHERS THEN
                             VNSFRST := 0;
                             END;

                  IF VNSFRST = 0  THEN  ----------como este alumno no a sido  insertado entonces lo hacemos

                               Begin
                                     select distinct max(sorlcur_key_seqno)
                                            into Vstudy
                                      from sorlcur
                                        where sorlcur_pidm        = PPIDM
                                        and     sorlcur_program   = VPROGRAMA
                                        and     sorlcur_lmod_code = 'LEARNER'
                                     --   AND     SORLCUR_CACT_CODE = 'ACTIVE'     ---- se quita filtro por Vic ramirez esto por que los alumnos que estan de baja y quieran una nivelacion no estan activos
                                        and     sorlcur_term_code = (select max(sorlcur_term_code) from sorlcur
                                                                        where   sorlcur_pidm=PPIDM
                                                                        and     sorlcur_program=VPROGRAMA
                                                                        and     sorlcur_lmod_code='LEARNER'
                                                                         --AND     SORLCUR_CACT_CODE = 'ACTIVE'---- se quita filtro por Vic ramirez esto por que los alumnos que estan de baja y quieran una nivelacion no estan activos
                                                                         )
                                        ;
                               Exception
                               when Others then
                                  Vstudy := null;
                                  VSALIDA  := 'Se presento un error al obtener la informacion de SORLCUR-key_seq_no ' ||PPIDM||'-'||  VPERIODO  ||'*'||crn|| sqlerrm;
                               End;

                                                Begin
                                                --   --dbms_output.put_line('Salida inserta sfrsctcr  21-D :'||PPIDM||'-'||  PPERIODO  ||'*'||crn||'*'|| Vgrupo||'*'||VPparte||'*'||credit_bill||'*'||credit||'*'||gmod||'*'||Pcampus);
                                                 --  INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , valor7) VALUES ('COMPACTA_GRUPOS_INSRT_SFRSTCR--00 ',Ppidm, PSEQ_NO,Pperiodo,crn, sysdate, SUBSTR(VSALIDA,1,500));

                                                    insert into sfrstcr values(
                                                                            VPERIODO,     --SFRSTCR_TERM_CODE
                                                                            Ppidm,     --SFRSTCR_PIDM
                                                                            crn,     --SFRSTCR_CRN
                                                                            1,     --SFRSTCR_CLASS_SORT_KEY
                                                                            Vgrupo,    --SFRSTCR_REG_SEQ
                                                                            VPparte,    --SFRSTCR_PTRM_CODE
                                                                            'RE',     --SFRSTCR_RSTS_CODE
                                                                            sysdate,    --SFRSTCR_RSTS_DATE
                                                                            null,    --SFRSTCR_ERROR_FLAG
                                                                            null,    --SFRSTCR_MESSAGE
                                                                            credit_bill,    --SFRSTCR_BILL_HR
                                                                            3, --SFRSTCR_WAIV_HR
                                                                            credit,     --SFRSTCR_CREDIT_HR
                                                                            credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                                                            credit,     --SFRSTCR_CREDIT_HR_HOLD
                                                                            gmod,     --SFRSTCR_GMOD_CODE
                                                                            null,    --SFRSTCR_GRDE_CODE
                                                                            null,    --SFRSTCR_GRDE_CODE_MID
                                                                            null,    --SFRSTCR_GRDE_DATE
                                                                            'N',    --SFRSTCR_DUPL_OVER
                                                                            'N',    --SFRSTCR_LINK_OVER
                                                                            'N',    --SFRSTCR_CORQ_OVER
                                                                            'N',    --SFRSTCR_PREQ_OVER
                                                                            'N',     --SFRSTCR_TIME_OVER
                                                                            'N',     --SFRSTCR_CAPC_OVER
                                                                            'N',     --SFRSTCR_LEVL_OVER
                                                                            'N',     --SFRSTCR_COLL_OVER
                                                                            'N',     --SFRSTCR_MAJR_OVER
                                                                            'N',     --SFRSTCR_CLAS_OVER
                                                                            'N',     --SFRSTCR_APPR_OVER
                                                                            'N',     --SFRSTCR_APPR_RECEIVED_IND
                                                                            sysdate,      --SFRSTCR_ADD_DATE
                                                                            sysdate,     --SFRSTCR_ACTIVITY_DATE
                                                                            Vnivel,     --SFRSTCR_LEVL_CODE
                                                                            Pcampus,     --SFRSTCR_CAMP_CODE
                                                                            vmateria,     --SFRSTCR_RESERVED_KEY
                                                                            null,     --SFRSTCR_ATTEND_HR
                                                                            'Y',     --SFRSTCR_REPT_OVER
                                                                            'N' ,    --SFRSTCR_RPTH_OVER
                                                                            null,    --SFRSTCR_TEST_OVER
                                                                            'N',    --SFRSTCR_CAMP_OVER
                                                                            'WWW_SIU',    --SFRSTCR_USER
                                                                            'N',    --SFRSTCR_DEGC_OVER
                                                                            'N',    --SFRSTCR_PROG_OVER
                                                                            null,    --SFRSTCR_LAST_ATTEND
                                                                            null,    --SFRSTCR_GCMT_CODE
                                                                            'WWW_SIU',    --SFRSTCR_DATA_ORIGIN
                                                                            sysdate,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                                            'N',  --SFRSTCR_DEPT_OVER
                                                                            'N',  --SFRSTCR_ATTS_OVER
                                                                            'N', --SFRSTCR_CHRT_OVER
                                                                            null, --SFRSTCR_RMSG_CDE
                                                                            null,  --SFRSTCR_WL_PRIORITY
                                                                            null,  --SFRSTCR_WL_PRIORITY_ORIG
                                                                            null,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                                            null, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                                            'N', --SFRSTCR_MEXC_OVER
                                                                            Vstudy,--SFRSTCR_STSP_KEY_SEQUENCE
                                                                            null,--SFRSTCR_BRDH_SEQ_NUM
                                                                            '01',--SFRSTCR_BLCK_CODE
                                                                            null,--SFRSTCR_STRH_SEQNO
                                                                            PSEQ_NO, --SFRSTCR_STRD_SEQNO
                                                                            null,  --SFRSTCR_SURROGATE_ID
                                                                            null, --SFRSTCR_VERSION
                                                                            'WWW_SIU',--SFRSTCR_USER_ID
                                                                            null );--SFRSTCR_VPDI_CODE
                                                 EXCEPTION WHEN OTHERS THEN
                                                   VSALIDA  := 'error ' ||sqlerrm;
                                                   --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , valor7) VALUES ('EERR_COMPACTA_GRUPOS_INSRT_SFRSTCR ',Ppidm, PSEQ_NO,Pperiodo,crn, sysdate, SUBSTR(VSALIDA,1,500));
                                                 end ;

                                        --   --dbms_output.put_line('DESPUES de insert stfrscr ' || PPIDM||'-'||PPERIODO||'-'|| crn|| Vgrupo||'-'||  VPparte||'  EXEX'  );
                                                        -- vl_error  :=  'SI INSERTA SFRSTCR OK ';
                                     --   INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , valor7) VALUES ('YAAAA  COMPACTA_GRUPOS_INSRT_SFRSTCR ',Ppidm, PSEQ_NO,Pperiodo,crn, sysdate, SUBSTR(VSALIDA,1,500));
                                      --  commit;
                                            --------SEGUNDA PARTE ACTUALIZA LOS ASIENTOS O CUPOS POR MATERIA----

                                    Begin
                                         update ssbsect SB
                                                set SB.ssbsect_enrl = SB.ssbsect_enrl + 1
                                          where SB.SSBSECT_TERM_CODE = VPERIODO
                                          And  SB.SSBSECT_CRN  = crn
                                          AND  SB.SSBSECT_PTRM_CODE = VPparte  ;
                                    Exception
                                    When Others then
                                    VSALIDA  := 'Se presento un error al actualizar el enrolamiento ' ||sqlerrm;
                                    End;

                                    Begin
                                            update ssbsect
                                                set ssbsect_seats_avail=ssbsect_seats_avail -1
                                            where SSBSECT_TERM_CODE = VPERIODO
                                             And  SSBSECT_CRN  = crn
                                             AND  SSBSECT_PTRM_CODE = VPparte ;
                                    Exception
                                    When Others then
                                        VSALIDA  := 'Se presento un error al actualizar la disponibilidad del grupo ' ||sqlerrm;
                                    End;

                                    Begin
                                             update ssbsect
                                                    set ssbsect_census_enrl=ssbsect_enrl
                                             Where SSBSECT_TERM_CODE = VPERIODO
                                             And   SSBSECT_CRN  = crn
                                              AND  SSBSECT_PTRM_CODE = VPparte ;
                                    Exception
                                    When Others then
                                        VSALIDA  := 'Se presento un error al actualizar el Censo del grupo ' ||sqlerrm;
                                    End;
                  ELSE ----SI EXISTE EL MISMO ALUMNO CON L MATERIA Y TODO IGUAL ENTONCES SOLO AJUSTAMOS EL ESTATUS A "RE"

                   UPDATE SFRSTCR  F
                     SET SFRSTCR_RSTS_CODE = 'RE',
                      SFRSTCR_ACTIVITY_DATE = SYSDATE,
                      SFRSTCR_STRD_SEQNO    = PSEQ_NO
                    WHERE  F.SFRSTCR_CRN     = CRN
                   AND F.SFRSTCR_TERM_CODE  = VPERIODO
                  AND F.SFRSTCR_PIDM       = PPIDM
                  and F.SFRSTCR_PTRM_CODE  = vpparte ;
                   VSALIDA := 'EXITO';

                      --  INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('COMPACTA_GRUPOS_UPDATE_SFRSTCR ',Ppidm, PSEQ_NO,Pperiodo,sysdate, SUBSTR(vl_error,1,500));
                      --  commit ;
                 END IF; -------HASTA AQUI TERMINA EL PRIMER Y SEGUNDO CASO SI YA EXISTE CRN ES LA COMPACTACION DE GRUPOS

            ELSE   -------QUIERE DECIR QUE TODO ES NUEVO E INSERTA TODO DESDE CERO---------
                        --- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_INICIO2 ',Ppidm, PSEQ_NO,VNIVEL, SUBSTR(vl_error,1,100), sysdate);

                    VSALIDA:='EXITO';  --- se reinicia la variable ya que esta entrando en otro proceso y deber ser valor  inicial null

                         begin
                             BEGIN

                                    select sztcrnv_crn
                                    into crn
                                    from SZTCRNV
                                    where 1 = 1
                                    and rownum = 1
                                    and sztcrnv_crn not in (select to_number(crn)
                                                            from
                                                            (
                                                            select case when
                                                                substr(SSBSECT_CRN,1,1) in('L','M','A','N','B') then to_number(substr(SSBSECT_CRN,2,10))
                                                               else
                                                                 to_number(SSBSECT_CRN)
                                                              end crn,
                                                               SSBSECT_CRN
                                                             from ssbsect
                                                              where 1 = 1
                                                              and ssbsect_term_code= Vperiodo
                                                            )
                                            where 1 = 1)
                                    order by 1;

                                EXCEPTION WHEN OTHERS THEN
                                raise_application_error (-20002,'Error al 2 '|| SQLCODE||' Error: '||SQLERRM);
                                ----dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                crn := NULL;
                                VSALIDA  := SQLERRM;
                                END;

                                  ----dbms_output.PUT_LINE('SALIDA De CRN :: '|| CRN );
                               --     INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_CRN ',Ppidm, PSEQ_NO,CRN, SUBSTR(vl_error,1,100),sysdate);
                                if Vnivel ='LI' then
                                crn:='L'||crn;

                                elsif  Vnivel ='MA' then
                                crn:='M'||crn;

                                elsif  Vnivel ='MS' then
                                crn:='A'||crn;

                                elsif  Vnivel ='DO' then
                                crn:='O'||crn;
                                
                                elsif  Vnivel ='BA' then
                                crn:='B'||crn;
                                
                                end if;

                              Exception
                                    When Others then
                                    crn := null;
                                    VSALIDA  := SQLERRM;
                          End;

                         --   --dbms_output.PUT_LINE('SALIDA D CRN COMPUESTO :: '|| CRN );
                        --   --dbms_output.PUT_LINE('SALIDA D FECHAS_INI_FIN :: '|| Pperiodo||'-'||VPparte );
                       --     INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('INSRT_HORARIO_FECHAS_antes22',Ppidm, PSEQ_NO,Pperiodo||'-'||VPparte, SUBSTR(vl_error,1,100), sysdate);
                             Begin

                               -- select distinct sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
                               select distinct TO_CHAR(sobptrm_start_date, 'DD/MM/YYYY') , TO_CHAR(sobptrm_end_date, 'DD/MM/YYYY') , sobptrm_weeks
                                into f_inicio, f_fin, sem
                                from sobptrm
                                where sobptrm_term_code  =Vperiodo
                                and     sobptrm_ptrm_code=VPparte
                                and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2);
                             Exception
                             When Others then
                                vl_error := 'No se Encontro fecha ini/ffin para el Periodo= ' ||Vperiodo ||' y Parte de Periodo= '||VPparte ||sqlerrm;
                              --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('INSRT_HORARIO_FECHAS_ERROORR22:: ',Ppidm, PSEQ_NO,Pperiodo||'-'||VPparte, SUBSTR(vl_error,1,200), sysdate);
                              VSALIDA  := SQLERRM;
                             End;
                           --   --dbms_output.PUT_LINE('SALIDA D FECHAS_INI_FIN :: '|| f_inicio||'-'||f_fin );
                            -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_FECHAS22',Ppidm, PSEQ_NO,F_INICIO||'-'||F_FIN, SUBSTR(vl_error,1,200), sysdate);
                        If crn is not null then
                                  Begin

                                  -- --dbms_output.put_line('Salida  20-A :'|| Pperiodo  ||'*'||crn||'*'|| VPparte||'*'||Vgrupo||'*'||schd||'*'||Vsubj||'**'||Vcrse   );
                                    -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_ssbsect22',Ppidm, PSEQ_NO,F_INICIO||'-'||F_FIN, SUBSTR(vl_error,1,100), sysdate);

                                     ------
                                        Insert into ssbsect values (
                                                                            Vperiodo,     --SSBSECT_TERM_CODE
                                                                            crn,     --SSBSECT_CRN
                                                                            VPparte,     --SSBSECT_PTRM_CODE
                                                                            Vsubj,     --SSBSECT_SUBJ_CODE
                                                                            Vcrse,     --SSBSECT_CRSE_NUMB
                                                                            Vgrupo,     --SSBSECT_SEQ_NUMB
                                                                            'A',    --SSBSECT_SSTS_CODE
                                                                             schd,    --SSBSECT_SCHD_CODE
                                                                             Pcampus,    --SSBSECT_CAMP_CODE
                                                                             title,   --SSBSECT_CRSE_TITLE
                                                                             credit,   --SSBSECT_CREDIT_HRS
                                                                             credit_bill,   --SSBSECT_BILL_HRS
                                                                             gmod,   --SSBSECT_GMOD_CODE
                                                                              null,  --SSBSECT_SAPR_CODE
                                                                              null, --SSBSECT_SESS_CODE
                                                                              null,  --SSBSECT_LINK_IDENT
                                                                              null,  --SSBSECT_PRNT_IND
                                                                              'Y',  --SSBSECT_GRADABLE_IND
                                                                               null,  --SSBSECT_TUIW_IND
                                                                               0, --SSBSECT_REG_ONEUP
                                                                               0, --SSBSECT_PRIOR_ENRL
                                                                               0, --SSBSECT_PROJ_ENRL
                                                                               50, --SSBSECT_MAX_ENRL
                                                                                0,--SSBSECT_ENRL
                                                                                50,--SSBSECT_SEATS_AVAIL
                                                                                null,--SSBSECT_TOT_CREDIT_HRS
                                                                                '0',--SSBSECT_CENSUS_ENRL
                                                                                TO_date(f_inicio, 'DD/MM/YYYY'),--SSBSECT_CENSUS_ENRL_DATE
                                                                                sysdate,--SSBSECT_ACTIVITY_DATE
                                                                                TO_date(f_inicio, 'DD/MM/YYYY'),--SSBSECT_PTRM_START_DATE
                                                                                TO_date(f_fin, 'DD/MM/YYYY'),--SSBSECT_PTRM_END_DATE
                                                                                sem,--SSBSECT_PTRM_WEEKS
                                                                                null,--SSBSECT_RESERVED_IND
                                                                                null, --SSBSECT_WAIT_CAPACITY
                                                                                null,--SSBSECT_WAIT_COUNT
                                                                                null,--SSBSECT_WAIT_AVAIL
                                                                                null,--SSBSECT_LEC_HR
                                                                                null,--SSBSECT_LAB_HR
                                                                                null,--SSBSECT_OTH_HR
                                                                                null,--SSBSECT_CONT_HR
                                                                                null,--SSBSECT_ACCT_CODE
                                                                                null,--SSBSECT_ACCL_CODE
                                                                                null,--SSBSECT_CENSUS_2_DATE
                                                                                null,--SSBSECT_ENRL_CUT_OFF_DATE
                                                                                null,--SSBSECT_ACAD_CUT_OFF_DATE
                                                                                null,--SSBSECT_DROP_CUT_OFF_DATE
                                                                                null,--SSBSECT_CENSUS_2_ENRL
                                                                                'Y',--SSBSECT_VOICE_AVAIL
                                                                                'N',--SSBSECT_CAPP_PREREQ_TEST_IND
                                                                                null,--SSBSECT_GSCH_NAME
                                                                                null,--SSBSECT_BEST_OF_COMP
                                                                                null,--SSBSECT_SUBSET_OF_COMP
                                                                                'NOP',--SSBSECT_INSM_CODE
                                                                                null,--SSBSECT_REG_FROM_DATE
                                                                                null,--SSBSECT_REG_TO_DATE
                                                                                null,--SSBSECT_LEARNER_REGSTART_FDATE
                                                                                null,--SSBSECT_LEARNER_REGSTART_TDATE
                                                                                null,--SSBSECT_DUNT_CODE
                                                                                null,--SSBSECT_NUMBER_OF_UNITS
                                                                                0,--SSBSECT_NUMBER_OF_EXTENSIONS
                                                                                'WWW_SIU',--SSBSECT_DATA_ORIGIN
                                                                                'WWW_SIU',--SSBSECT_USER_ID
                                                                                'MOOD',--SSBSECT_INTG_CDE
                                                                                'B',--SSBSECT_PREREQ_CHK_METHOD_CDE
                                                                                user,--SSBSECT_KEYWORD_INDEX_ID
                                                                                null,--SSBSECT_SCORE_OPEN_DATE
                                                                                null,--SSBSECT_SCORE_CUTOFF_DATE
                                                                                null,--SSBSECT_REAS_SCORE_OPEN_DATE
                                                                                null,--SSBSECT_REAS_SCORE_CTOF_DATE
                                                                                null,--SSBSECT_SURROGATE_ID
                                                                                null,--SSBSECT_VERSION
                                                                                PSEQ_NO);--SSBSECT_VPDI_CODE
                                    Exception
                                    When Others then
                                   --  INSERT INTO TWPASOW (VALOR1,VALOR2,VALOR3,VALOR4,VALOR5 ) VALUES ('ERROR_INSRT_HORARIO_SSBSECT22  ',Ppidm, PSEQ_NO,VPparte, SUBSTR(vl_error,1,100));
                                      vl_error := 'Se presento un Error al insertar el nuevo grupo ' ||sqlerrm;
                                      VSALIDA  := SQLERRM;
                                  End;
                            --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('INSERTA_HORARIO_SSBSET22 ',Ppidm, PSEQ_NO,Vsubj||'-'||Vcrse, sysdate, SUBSTR(vl_error,1,500));
                                                   Begin
                                                                update SOBTERM
                                                                     set SOBTERM_CRN_ONEUP = crn
                                                                where SOBTERM_TERM_CODE = Vperiodo;
                                                   Exception
                                                   When Others then
                                                     null;
                                                   End;

                               BEGIN
                                 select count(1)
                                     INTO cssrmet
                                    from  ssrmeet
                                  where SSRMEET_TERM_CODE = Vperiodo
                                  and SSRMEET_CRN = crn;

                                EXCEPTION WHEN OTHERS THEN
                                  VSALIDA  := SQLERRM;
                                  cssrmet := 0;
                                END;

                                            if cssrmet = 1 then
                                                null;
                                             else
                                                   Begin

                                                        insert into ssrmeet values(Vperiodo, crn, null,null,null,null,null,null, sysdate, TO_date(f_inicio, 'DD/MM/YYYY'), TO_date(f_fin, 'DD/MM/YYYY'), '01', null,null,null,null,null,null,null, 'ENL', null, credit, null, 0, null,null,null, 'CLVI', 'WWW_SIU', 'WWW_SIU', null,null,PSEQ_NO);
                                                    Exception
                                                    when Others then
                                                       VSALIDA  := 'Se presento un Error al insertar en ssrmeet ' ||sqlerrm;
                                                   End;
                                             end if;
                                        ---------AQUI BUSCAMOS EL PROFESOR DENTRO DE LA PARAMETRIZACION-------
                                                    begin

                                                        select ZSTPARA_PARAM_VALOR
                                                          INTO pidm_prof
                                                        from ZSTPARA
                                                        where ZSTPARA_MAPA_ID = 'DOCENTE_NIVELAC'
                                                        and  ZSTPARA_PARAM_DESC = VMATERIA;

                                                    Exception when others then
                                                      pidm_prof:=NULL;
                                                      VSALIDA  := 'EXITO';

                                                    End;

                                              if pidm_prof is null then
                                                   null; --NO HACE NADA--- PERO SIGUE EL FLUJO NO INSERTA EL PROFESOR  PARA CUANDO NO ESTA
                                                   -------CONFIGURADO EL PROFESOR EN EL PARAMETRIZADOR
                                              ELSE
                                                      ----dbms_output.put_line('Crea el CRN para el docente:'|| pidm_prof  ||'*'||crn);

                                                 --------------------convierte el id del profesor en su pidm----
                                                       select FGet_pidm(pidm_prof) into pidm_prof2  from dual;
                                                 ------------------------------------------------------------------

                                                      Begin
                                                            Select count (1)
                                                            Into vl_exite_prof
                                                            from sirasgn
                                                            Where SIRASGN_TERM_CODE = VPERIODO
                                                            And SIRASGN_CRN = crn
                                                            And SIRASGN_PIDM = pidm_prof2;
                                                       Exception
                                                        when others then
                                                          vl_exite_prof := 0;
                                                          VSALIDA  := 'Se presento un Error al consultal sirasgn ' ||sqlerrm;
                                                          -- insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6, valor7) values('ERRORRR_profe_mate11  ',ppidm, pidm_prof2,PPERIODO,crn,vl_exite_prof, sysdate );commit;
                                                       End;

                                                        -------------------------
                                                       If vl_exite_prof = 0 then
                                                                Begin
                                                                ----dbms_output.put_line('Salida inserta profe  20-B :'|| PPERIODO  ||'*'||crn||'*'|| pidm_prof||'*'||Vsubj||'*'||Vcrse||'*'||Vgrupo||'*'||schd||'*'||Pcampus);
                                                                --insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6) values('inserta_profe_mate22  ',ppidm , pidm_prof2,PPERIODO,crn, sysdate );commit;

                                                                select count(1)
                                                                  INTO csirasgn
                                                                from sirasgn
                                                                where SIRASGN_TERM_CODE = VPERIODO
                                                                and  SIRASGN_CRN       = crn
                                                                and  SIRASGN_PIDM      = pidm_prof2
                                                                and  SIRASGN_CATEGORY  = '01'
                                                                ;

                                                                if csirasgn > 0 then
                                                                null;
                                                                else
                                                                insert into sirasgn values(VPERIODO, crn, pidm_prof2, '01', 100, null, 100,'Y', null, null,
                                                                                            sysdate, null,null,null,null, 'WWW_SIU', 'WWW_SIU', null, null, null, null,  null,PSEQ_NO);

                                                                end if;
                                                                Exception
                                                                When Others then
                                                                 VSALIDA  := 'Se presento un Error al consultal sirasgn_count ' ||sqlerrm;
                                                                null;
                                                                End;
                                                       Else
                                                               Begin
                                                                    Update sirasgn
                                                                    set SIRASGN_PRIMARY_IND = null
                                                                     Where SIRASGN_TERM_CODE = VPERIODO
                                                                     And SIRASGN_CRN = crn;
                                                               Exception
                                                                When others then
                                                                 VSALIDA  := 'Se presento un Error al UPDATE sirasgn ' ||sqlerrm;
                                                                null;
                                                               End;

                                                                Begin
                                                                -----dbms_output.put_line('Salida INST EXEX  20-C :'|| PPERIODO  ||'*'||crn||'*'|| pidm_prof||'*'||Vsubj||'*'||Vcrse||'*'||VGrupo||'*'||schd||'*'||Pcampus);

                                                                --insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6) values('inserta_profe_mate33 ',ppidm, pidm_prof2,PPERIODO,crn, sysdate );commit;

                                                                        insert into sirasgn values(VPERIODO, crn, pidm_prof2, '01', 100, null, 100,'Y', null, null,
                                                                                                             sysdate, null,null,null,null, 'WWW_SIU', 'WWW_SIU', null, null, null, null,  null,PSEQ_NO);
                                                                Exception
                                                                When Others then
                                                                 VSALIDA  := 'Se presento un Error al INSERTAR sirasgn ' ||sqlerrm;
                                                                null;
                                                                End;

                                                       End if;
                                                end if;


                                                conta_ptrm :=0;
                                               ----dbms_output.put_line('salida 21  '||PPIDM ||'-'|| VPROGRAMA );
                                                    Begin
                                                         select count(*)
                                                            into conta_ptrm
                                                         from sfbetrm
                                                         where sfbetrm_term_code=VPERIODO
                                                         and     sfbetrm_pidm=PPIDM;
                                                    Exception
                                                        When Others then
                                                          conta_ptrm := 0;
                                                           VSALIDA  := 'Se presento un Error al conunt sfbetrm ' ||sqlerrm;
                                                    End;


                                                     if conta_ptrm =0 then
                                                            Begin
                                                                    insert into sfbetrm values(VPERIODO, PPIDM, 'EL', sysdate, 99.99, 'Y', null, sysdate, sysdate, null,null,null,null,'WWW_SIU', null,'WWW_SIU', null, 0,null,null, null,null,user,PSEQ_NO);
                                                            Exception
                                                            When Others then
                                                                VSALIDA  := ('Se presento un error al insertar en la tabla sfbetrm ' || sqlerrm);
                                                               --insert into twpasow(valor1,valor2,valor3,valor4, valor5) values('ERROR_inserta_sfbetrm22 ',pidm_prof2,PPERIODO,crn, sysdate );commit;
                                                            End;
                                                     end if;

                                             Begin
                                                     select distinct max(sorlcur_key_seqno)
                                                            into Vstudy
                                                      from sorlcur
                                                        where sorlcur_pidm        = PPIDM
                                                        and     sorlcur_program   = VPROGRAMA
                                                        and     sorlcur_lmod_code = 'LEARNER'
                                                      --  AND     SORLCUR_CACT_CODE = 'ACTIVE'
                                                        and     sorlcur_term_code = (select max(sorlcur_term_code) from sorlcur
                                                                                        where   sorlcur_pidm=PPIDM
                                                                                        and     sorlcur_program=VPROGRAMA
                                                                                        and     sorlcur_lmod_code='LEARNER'
                                                                                         --AND     SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                         )
                                                        ;
                                               Exception
                                               when Others then
                                                  Vstudy := 1;
                                                  VSALIDA  := 'Se presento un error al obtener la informacion de SORLCUR-key_seq_no ' ||PPIDM||'-'||  VPERIODO  ||'*'||crn|| sqlerrm;
                                               End;

                                        BEGIN

                                            SELECT COUNT(1)
                                            INTO VNSFRST
                                            FROM SFRSTCR  F
                                            WHERE  F.SFRSTCR_CRN     = crn
                                            AND F.SFRSTCR_TERM_CODE  =  VPERIODO
                                            AND F.SFRSTCR_PIDM       = PPIDM;

                                         EXCEPTION WHEN OTHERS THEN
                                         VNSFRST := 0;
                                          VSALIDA  := 'Se presento un Error al count sfrstrc  ' ||sqlerrm;
                                         END;
                                --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , VALOR7, VALOR8 ) VALUES ('PASOWW_SIU_INSERT_SFRSTCR_ANTES ',Ppidm, PPERIODO,crn||'-'||VPparte,sysdate,  Vstudy , VNSFRST, VSALIDA);
                               -- COMMIT;
                                IF VNSFRST = 0  THEN
                                                   Begin
                                                 --  --dbms_output.put_line('Salida inserta sfrsctcr  21-D :'||PPIDM||'-'||  PPERIODO  ||'*'||crn||'*'|| Vgrupo||'*'||VPparte||'*'||credit_bill||'*'||credit||'*'||gmod||'*'||Pcampus);


                                                    insert into sfrstcr values(
                                                                                        VPERIODO,     --SFRSTCR_TERM_CODE
                                                                                        Ppidm,     --SFRSTCR_PIDM
                                                                                        crn,     --SFRSTCR_CRN
                                                                                        1,     --SFRSTCR_CLASS_SORT_KEY
                                                                                        Vgrupo,    --SFRSTCR_REG_SEQ
                                                                                        VPparte,    --SFRSTCR_PTRM_CODE
                                                                                        'RE',     --SFRSTCR_RSTS_CODE
                                                                                        sysdate,    --SFRSTCR_RSTS_DATE
                                                                                        null,    --SFRSTCR_ERROR_FLAG
                                                                                        null,    --SFRSTCR_MESSAGE
                                                                                        credit_bill,    --SFRSTCR_BILL_HR
                                                                                        3, --SFRSTCR_WAIV_HR
                                                                                        credit,     --SFRSTCR_CREDIT_HR
                                                                                        credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                                                                        credit,     --SFRSTCR_CREDIT_HR_HOLD
                                                                                        gmod,     --SFRSTCR_GMOD_CODE
                                                                                        null,    --SFRSTCR_GRDE_CODE
                                                                                        null,    --SFRSTCR_GRDE_CODE_MID
                                                                                        null,    --SFRSTCR_GRDE_DATE
                                                                                        'N',    --SFRSTCR_DUPL_OVER
                                                                                        'N',    --SFRSTCR_LINK_OVER
                                                                                        'N',    --SFRSTCR_CORQ_OVER
                                                                                        'N',    --SFRSTCR_PREQ_OVER
                                                                                        'N',     --SFRSTCR_TIME_OVER
                                                                                        'N',     --SFRSTCR_CAPC_OVER
                                                                                        'N',     --SFRSTCR_LEVL_OVER
                                                                                        'N',     --SFRSTCR_COLL_OVER
                                                                                        'N',     --SFRSTCR_MAJR_OVER
                                                                                        'N',     --SFRSTCR_CLAS_OVER
                                                                                        'N',     --SFRSTCR_APPR_OVER
                                                                                        'N',     --SFRSTCR_APPR_RECEIVED_IND
                                                                                        sysdate,      --SFRSTCR_ADD_DATE
                                                                                        sysdate,     --SFRSTCR_ACTIVITY_DATE
                                                                                        Vnivel,     --SFRSTCR_LEVL_CODE
                                                                                        Pcampus,     --SFRSTCR_CAMP_CODE
                                                                                        vmateria,     --SFRSTCR_RESERVED_KEY
                                                                                        null,     --SFRSTCR_ATTEND_HR
                                                                                        'Y',     --SFRSTCR_REPT_OVER
                                                                                        'N' ,    --SFRSTCR_RPTH_OVER
                                                                                        null,    --SFRSTCR_TEST_OVER
                                                                                        'N',    --SFRSTCR_CAMP_OVER
                                                                                        'WWW_SIU',    --SFRSTCR_USER
                                                                                        'N',    --SFRSTCR_DEGC_OVER
                                                                                        'N',    --SFRSTCR_PROG_OVER
                                                                                        null,    --SFRSTCR_LAST_ATTEND
                                                                                        null,    --SFRSTCR_GCMT_CODE
                                                                                        'WWW_SIU',    --SFRSTCR_DATA_ORIGIN
                                                                                        sysdate,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                                                        'N',  --SFRSTCR_DEPT_OVER
                                                                                        'N',  --SFRSTCR_ATTS_OVER
                                                                                        'N', --SFRSTCR_CHRT_OVER
                                                                                        null, --SFRSTCR_RMSG_CDE
                                                                                        null,  --SFRSTCR_WL_PRIORITY
                                                                                        null,  --SFRSTCR_WL_PRIORITY_ORIG
                                                                                        null,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                                                        null, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                                                        'N', --SFRSTCR_MEXC_OVER
                                                                                        Vstudy,--SFRSTCR_STSP_KEY_SEQUENCE
                                                                                        null,--SFRSTCR_BRDH_SEQ_NUM
                                                                                        '01',--SFRSTCR_BLCK_CODE
                                                                                        null,--SFRSTCR_STRH_SEQNO
                                                                                        PSEQ_NO, --SFRSTCR_STRD_SEQNO
                                                                                        null,  --SFRSTCR_SURROGATE_ID
                                                                                        null, --SFRSTCR_VERSION
                                                                                        'WWW_SIU',--SFRSTCR_USER_ID
                                                                                        null );--SFRSTCR_VPDI_CODE

                                                         ----dbms_output.put_line('DESPUES de insert stfrscr ' || PPIDM||'-'||PPERIODO||'-'|| crn|| Vgrupo||'-'||  VPparte||'NIVE'  );
                                                        -- vl_error  :=  'SI INSERTA SFRSTCR OK ';
                                                        --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('INSRT_SFRSTCR_SEGUNDO22 ',Ppidm, PSEQ_NO,Pperiodo,sysdate, SUBSTR(vl_error,1,500));

                                                                Begin
                                                                     update ssbsect
                                                                            set ssbsect_enrl = ssbsect_enrl + 1
                                                                      where SSBSECT_TERM_CODE = VPERIODO
                                                                      And SSBSECT_CRN  = crn;
                                                                Exception
                                                                When Others then
                                                                VSALIDA  := 'Se presento un error al actualizar el enrolamiento ' ||sqlerrm;
                                                                End;

                                                                Begin
                                                                        update ssbsect
                                                                            set ssbsect_seats_avail=ssbsect_seats_avail -1
                                                                        where SSBSECT_TERM_CODE = VPERIODO
                                                                         And SSBSECT_CRN  = crn;
                                                                Exception
                                                                When Others then
                                                                    VSALIDA  := 'Se presento un error al actualizar la disponibilidad del grupo ' ||sqlerrm;
                                                                End;

                                                                Begin
                                                                         update ssbsect
                                                                                set ssbsect_census_enrl=ssbsect_enrl
                                                                         Where SSBSECT_TERM_CODE = VPERIODO
                                                                         And SSBSECT_CRN  = crn;
                                                                Exception
                                                                When Others then
                                                                    VSALIDA  := 'Se presento un error al actualizar el Censo del grupo ' ||sqlerrm;
                                                                End;

                                                                Begin
                                                                    Update sgbstdn a
                                                                    set a.SGBSTDN_STYP_CODE ='C',
                                                                        A.SGBSTDN_USER_ID  = 'WWW_SIU'
                                                                    Where a.SGBSTDN_PIDM = Ppidm
                                                                    And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                                                                           from sgbstdn a1
                                                                                                                           Where a1.SGBSTDN_PIDM = a.SGBSTDN_PIDM
                                                                                                                           And a1.SGBSTDN_PROGRAM_1 = a.SGBSTDN_PROGRAM_1)
                                                                     And a.SGBSTDN_PROGRAM_1 = VPROGRAMA;
                                                                Exception
                                                                    When Others then
                                                                    VSALIDA  := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||sqlerrm;
                                                                End;



                                                                conta_ptrm:=0;

                                                                Begin
                                                                    Select count (*)
                                                                        Into conta_ptrm
                                                                    from sfrareg
                                                                    where SFRAREG_PIDM = Ppidm
                                                                    And SFRAREG_TERM_CODE = VPERIODO
                                                                    And SFRAREG_CRN = crn
                                                                    And SFRAREG_EXTENSION_NUMBER = 0
                                                                    And SFRAREG_RSTS_CODE = 'RE';
                                                                Exception
                                                                When Others then
                                                                   conta_ptrm :=0;
                                                                    VSALIDA  := 'Se presento un Error al count sfrareg ' ||sqlerrm;
                                                                End;

                                                                If conta_ptrm = 0 then

                                                                     Begin
                                                                       ----dbms_output.put_line(' SALIDA 22A--antes de insertar sfrareg  ' || Ppidm||'-'||PPERIODO||'-'|| crn||f_inicio||'-'|| f_fin||'-'|| 'N'||'-'||'N'   );
                                                                        if  f_inicio is not null  then
                                                                             insert into sfrareg values(PPIDM, VPERIODO, crn , 0, 'RE', TO_date(f_inicio, 'DD/MM/YYYY'), TO_date(f_fin, 'DD/MM/YYYY'), 'N','N', sysdate, 'WWW_SIU', null,null,null,null,null,null,null,null, 'WWW_SIU', sysdate, null,null,PSEQ_NO);
                                                                        end if;

                                                                     Exception
                                                                       When Others then
                                                                          VSALIDA  := 'error al insertar el registro de la materia para sfrareg  ' ||sqlerrm;
                                                                     End;
                                                                End if;
                                                      -- commit;
                                                    Exception
                                                   when Others then
                                                    ----INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4, valor6 )  VALUES ('PASOWWW_SIU_GRal',Ppidm, PSEQ_NO,sysdate,  SUBSTR(vl_error,1,100));
                                                       VSALIDA  := 'Se presento un error al insertar al alumno en el grupo3  ' ||sqlerrm;
                                                End;
                                  END IF;
                                    -- commit;
                                                  ----dbms_output.put_line('se termina proceso gral ' ||VSALIDA);
                         else
                            VSALIDA  := 'No inserto Horario: ' ||sqlerrm;
                        --  INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_FINALIZA ',Ppidm, PSEQ_NO,Pperiodo, SUBSTR(vl_error,1,100), sysdate);
                        End if;
             END IF; -----ES EL FIN FINAL DE LA COMPACTACION DE GRUPO

    IF VSALIDA = 'EXITO' then
    null;

    pregreso := 'EXITO';
     ---------------------------aqui va el update con el numero de recibo nuevo glovicx 26/11/2019

       begin  -------------AQUI BUSCA EL NUMERO DE ORDEN ACTUAL EL MAS RECIENTE
        select MAX(TBRACCD_RECEIPT_NUMBER)
        into vno_orden
            from tbraccd t
            where tbraccd_pidm =  ppidm
            and TBRACCD_DESC like ('%NIVELA%')
           -- and t.TBRACCD_DOCUMENT_NUMBER = vmateria
           -- and t.TBRACCD_USER       =  'WWW_SIU'
           AND TBRACCD_CROSSREF_NUMBER = PSEQ_NO
           ;
     exception when others then

     vno_orden := 0;
     end;

         BEGIN
                       -------BUSCA SI EL CRN YA EXISTIA Y TENIA UN NUMERO DE ORDEN POR LA COMPACTACION DE GRUPO
                       ------- SI YA EXISTE ENTONCES TENGO QUE RECUPERAR ESA ORDEN Y ACTUALIZARLA EN LA CARTERA CANCELADA
                       -----  ESTA REGLA SE ACORDO CON VICTOR RAMIREZ 04/12/2019-----
            SELECT SFRSTCR_VPDI_CODE
            INTO NO_ORDEN_OLD
            FROM SFRSTCR
            where 1= 1
            and SFRSTCR_PIDM = ppidm
            and SFRSTCR_CRN  = CRN
            And substr (SFRSTCR_TERM_CODE, 5,1) = '8'
            And SFRSTCR_RSTS_CODE = 'RE'
            ;

         EXCEPTION WHEN OTHERS THEN
           NO_ORDEN_OLD := 0;
         END;

       IF NO_ORDEN_OLD > 0 THEN-----SI HAY NUMERO DE ORDEN VIEJO LO ACTUALIZA EN LA CARTERA VIEJA POR EL NUEVO NUM ORDEN

          UPDATE  tbraccd t
            SET TBRACCD_RECEIPT_NUMBER = vno_orden --NO_ORDEN_NUEVO
            where tbraccd_pidm =  ppidm
            and TBRACCD_DESC like ('%NIVELA%')
            --and t.TBRACCD_DOCUMENT_NUMBER like (:vmateria
            AND TBRACCD_RECEIPT_NUMBER = NO_ORDEN_OLD  --NO_ORden anterior
            ;
       END IF;

     if vno_orden > 0 then
       ----dbms_output.put_line('salida no_orden '||vno_orden );
       begin

          update  SFRSTCR
             set SFRSTCR_VPDI_CODE  = vno_orden,
               SFRSTCR_ADD_DATE     = sysdate
              where 1= 1
               and SFRSTCR_PIDM = ppidm
               and SFRSTCR_CRN  = CRN
               And substr (SFRSTCR_TERM_CODE, 5,1) = '8'
               And SFRSTCR_RSTS_CODE = 'RE';

        --  --dbms_output.put_line('Actualiza::  '||vno_orden||'-'|| jump.pidm ||'--'||jump.CRN ||'--'||jump.materia );
       exception when others then
       null;
        ----dbms_output.put_line('error en UPDATE :  ' ||sqlerrm  );
        end;


     end if;

     ---------------------------------------------------------------------------------fin
     --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWW_SIU_FINALIZA_HORARIO ',Ppidm, PSEQ_NO,sysdate,  pregreso,SUBSTR(vl_error,1,90));
     COMMIT;
     ----dbms_output.put_line('se termina proceso gral--1 ' ||pregreso);
    else
    pregreso := sqlerrm;
     ----dbms_output.put_line('se termina proceso gral--3 ' ||VSALIDA);
--     INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWW_SIU_FINALIZA_HORARIO_ERROR ',Ppidm, PSEQ_NO,sysdate,  pregreso,SUBSTR(VSALIDA,1,90));
--     COMMIT;
     --rollback;
--     INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWW_SIU_FINALIZA_HORARIO_ERROR ',Ppidm, PSEQ_NO,sysdate,  pregreso,SUBSTR(VSALIDA,1,500));
--     COMMIT;

    end if;
-- INSERT INTO TWPASO VALUES ('PASOWWW_SIU_FIN',Ppidm, PSEQ_NO, vl_error);
-- COMMIT;

--commit;
END IF;
exception when others then
     -----dbms_output.put_line('ERRORR:  termina proceso gral ' ||VSALIDA);
   --pregreso := VSALIDA;
  --- rollback;
  NULL;
-- raise_application_error (-20002,'ERROR EN CARGA HORARIO '||vl_error||'-++'|| sqlerrm);
end P_inserta_horario;


procedure p_cancela_horario ( ppidm  in number, pmateria in varchar2 )
IS

VCUENTA_ALUM      number:= 0;
vmateria          varchar2(12);
VCRN              varchar2(5);
nborra            number;
vperiodo          varchar2(12);
NUMEROD           NUMBER:=0;
V_SEQ_NO          NUMBER:=0;
VPROGRAMA         VARCHAR2(14);

begin

IF  PPIDM IS NOT NULL THEN
 NUMEROD := 0;
 --   --dbms_output.put_line('INICIO SII HAY PIDM  '|| NUMEROD);
 ELSE
 NUMEROD :=3;
 ----dbms_output.put_line('INICIO2 NOO HAY PIDM'|| NUMEROD);
END IF;
--        IF  pprograma  IS NULL  THEN
--             BEGIN
--                select V.SVRSVPR_PROTOCOL_SEQ_NO ,
--                   SVRSVAD_ADDL_DATA_CDE  PROG
--                     INTO V_SEQ_NO, VPROGRAMA
--                   from svrsvpr v,SVRSVAD VA
--                        where SVRSVPR_SRVC_CODE = pcode
--                           AND  SVRSVPR_PIDM   = ppidm
--                           AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PSEQ_NO
--                           and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
--                           and va.SVRSVAD_ADDL_DATA_SEQ in ( 1) ; ------el valor 2 es para la parte de periodo
--             EXCEPTION WHEN OTHERS THEN
--               VPROGRAMA :='';
--               V_SEQ_NO := 0;
--              END;
--        END IF;
--null;
-------------------------------------recupera los datos de materia  cancelar--------------------
--  BEGIN
--                select
--                     case  when INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1) > 0 then
--                          SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1)
--                           else
--                          SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10)-1 )
--                      end as periodo
--                     INTO  vperiodo
--                   from svrsvpr v,SVRSVAD VA
--                        where SVRSVPR_SRVC_CODE = pcode
--                           AND  SVRSVPR_PIDM   = ppidm
--                            AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PNO_SERV
--                           and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
--                           and va.SVRSVAD_ADDL_DATA_SEQ in ( 6) ; ------el valor 2 es pare el  periodo
--             EXCEPTION WHEN OTHERS THEN
--              null;
--
--             END;
--

 FOR  jump in   (
                  select distinct datos.seq_no, datos.pidm , datos.code,
                            datos.fecha,datos.no_tran
                           ,hh.SVRSVAD_ADDL_DATA_CDE programa
                           ,datos.materia  materia
                     from (
                       SELECT distinct SVRSVPR_PROTOCOL_SEQ_NO seq_no, SVRSVPR_PIDM pidm , SVRSVPR_SRVC_CODE code,
                                        SVRSVPR_RECEPTION_DATE fecha,SVRSVPR_ACCD_TRAN_NUMBER no_tran
                                      --  , substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1 ) materia
                                         ,h.SVRSVAD_ADDL_DATA_CDE materia
                                  FROM SVRSVPR p, SVRSVAD h
                                          WHERE     p.SVRSVPR_SRVC_CODE   in ( 'NIVE', 'NABA')
                                           --    AND p.SVRSVPR_SRVS_CODE   = 'AC'
                                               AND h.SVRSVAD_PROTOCOL_SEQ_NO = p.SVRSVPR_PROTOCOL_SEQ_NO
                                               AND  TRUNC(p.SVRSVPR_STATUS_DATE) >= '21/06/2019'  --ESTA FECHA ASI SE QUEDA ES EL DIA DE LA LIBERACION A PRODUCION WEB_SIU
                                             --  AND SVRSVPR_DATA_ORIGIN !=  'BAJA_JOB'
                                             --  AND TRUNC(p.SVRSVPR_RECEPTION_DATE) <= trunc(sysdate)-NUMEROD
                                               and p.SVRSVPR_PIDM  =  nvl(ppidm, p.SVRSVPR_PIDM )
                                               --AND substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1 ) = nvl(pmateria,substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1 )  ) --'L1C101'
                                                and   h.SVRSVAD_ADDL_DATA_CDE =  nvl(pmateria, h.SVRSVAD_ADDL_DATA_CDE  )
                                      )datos, SVRSVAD hh
                     where 1=1
                     and datos.SEQ_NO = hh.SVRSVAD_PROTOCOL_SEQ_NO
                       AND HH.SVRSVAD_ADDL_DATA_SEQ  = 1 )

       loop

           ----dbms_output.put_line('INICIO 0 regresa materia:.'||jump.seq_no||'-'|| jump.pidm||'-mater--'|| pmateria||'--'||vperiodo||'-crn-'||VCRN);
         ---------------------------------------obtiene el periodo-----------
         begin
            select  SVRSVAD_ADDL_DATA_CDE periodo
                INTO vperiodo
                from SVRSVAD
                where SVRSVAD_PROTOCOL_SEQ_NO = jump.seq_no
                and   SVRSVAD_ADDL_DATA_SEQ = 6;

         exception when others then
         vperiodo  := '';
         end;
         -----dbms_output.put_line('INICIO 1 regresa periodo:.'||jump.seq_no||'-'|| jump.pidm||'-'|| jump.materia||'-perid-'||vperiodo||'-crn-'||VCRN);
------------------------------------busca el CRN con l materia------------------------
        begin
            select SFRSTCR_CRN
                 INTO VCRN
                 FROM SFRSTCR f, ssbsect b
                   WHERE     F.SFRSTCR_CRN     = B.SSBSECT_CRN
                      AND F.SFRSTCR_TERM_CODE  = B.SSBSECT_TERM_CODE
                      AND F.SFRSTCR_PIDM       = jump.pidm
                      and F.SFRSTCR_TERM_CODE  = vperiodo
                      AND SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB =  jump.materia;
          exception when others then
         VCRN  := '';
         end;
                      --and SFRSTCR_RSTS_CODE  = 'RE'  ;
         -------dbms_output.put_line('INICIO 2 regresa CRN:.'||jump.seq_no||'-'|| jump.pidm||'-'|| jump.materia||'--'||vperiodo||'-crn-'||VCRN);
---------------------1.- borra tabla sfrstcr que es hija---  cuenta si hay mas de un alumno en el mismo crn

            SELECT COUNT(*)
            INTO  VCUENTA_ALUM
            FROM sfrstcr
            where 1=1
            --SFRSTCR_DATA_ORIGIN ='SIU_SSB'
            and   SFRSTCR_STRD_SEQNO   = jump.seq_no
            and   SFRSTCR_TERM_CODE   = vperiodo
            and  SFRSTCR_PIDM         = jump.pidm
            AND  SFRSTCR_CRN          = VCRN
            and SFRSTCR_RSTS_CODE     = 'RE'
            ;
----------------si existe cuenta mas de uno entonces no borra el s
-- --dbms_output.put_line('antes de entrar >>>:.'||jump.seq_no||'-'|| jump.pidm||'-'|| jump.materia||'--'||vperiodo||'-'|| vcrn );
 --insert into twpasow (valor1, valor2, valor3, valor4, valor5, valor6  ) values ('BORANDO HORAIO ANTES', jump.seq_no,jump.pidm,jump.materia,vperiodo, vcrn  );
commit;
IF VCUENTA_ALUM >= 1  THEN
NULL;
--insert into twpasow (valor1, valor2, valor3, valor4, valor5, valor6  ) values ('BORANDO HORAIO ANTES2', jump.seq_no,jump.pidm,jump.materia,vperiodo, vcrn  );
--commit;
----dbms_output.put_line('DENTRO de alumno> 1  >>>:.'||jump.seq_no||'-'|| jump.pidm||'-'|| jump.materia||'--'||vperiodo||'-'|| vcrn );
       -----------------borra el maestro primero-------------
       -------------BORRANDO SIRASGN-----
--         begin
--             DELETE
--                FROM sirasgn ss
--               where  1=1
--                    and SS.SIRASGN_TERM_CODE  = vperiodo
--                    and ss.SIRASGN_CRN           =VCRN
--                    AND  ss.SIRASGN_VPDI_CODE   =  jump.seq_no ;
--
--                 --dbms_output.put_line('borra  sirasgn||' ||sql%rowcount );
--         exception when others then
--       --dbms_output.put_line('borra sirasgn..||'|| sqlerrm  );
--       end;


     -------HACE EL BORRADO---ssbsect----
--      begin
--         DELETE
--            FROM ssbsect st
--              WHERE st.ssbsect_DATA_ORIGIN ='WWW_SIU'
--               AND  st.SSBSECT_CRN         = VCRN
--               and  ST.SSBSECT_TERM_CODE   = vperiodo
--               AND  st.SSBSECT_VPDI_CODE   = jump.seq_no;
--               --dbms_output.put_line('borra  ssbsect||' ||sql%rowcount );
--       exception when others then
--       --dbms_output.put_line('borra ssbsect..||'|| sqlerrm  );
--       end;
--
            -----------hay que actualizar   poner en DD -------------
      begin
--           DELETE
--                FROM sfrstcr
--                where SFRSTCR_DATA_ORIGIN ='WWW_SIU'
--                  AND SFRSTCR_PIDM        = jump.PIDM
--                  AND SFRSTCR_CRN         = VCRN
--                  AND SFRSTCR_STRD_SEQNO  = jump.seq_no
--                  and SFRSTCR_TERM_CODE   = jump.periodo
--                  ;
           null;
              UPDATE sfrstcr
              SET   SFRSTCR_RSTS_CODE = 'DD',
                    SFRSTCR_DATA_ORIGIN ='WWW_CANX' ,
                    SFRSTCR_ACTIVITY_DATE  = sysdate,
                    SFRSTCR_RSTS_DATE      = sysdate
                 where 1=1
                  AND SFRSTCR_PIDM        = jump.PIDM
                  AND SFRSTCR_CRN         = VCRN
                  AND SFRSTCR_STRD_SEQNO  = jump.seq_no
                  and SFRSTCR_TERM_CODE   = vperiodo
                 ;


            ----dbms_output.put_line('borra  sfrstcr||' ||sql%rowcount );
       exception when others then
       ----dbms_output.put_line('borra sfrtscr..||'|| sqlerrm  );
       NULL;
       end;
          --------HACE EL BORRADO DEL HORARIO----
--     begin
--          DELETE
--           FROM sfbetrm
--               where SFBETRM_DATA_ORIGIN ='SIU_SSB'
--                 AND   SFBETRM_VPDI_CODE  = jump.seq_no
--                 AND  SFBETRM_PIDM        = jump.PIDM
--                 and  SFBETRM_TERM_CODE   = jump.periodo;
--
--               --dbms_output.put_line('borra  sfbetrm||'||sql%rowcount  );
--        exception when others then
--       --dbms_output.put_line('borra sfbetrm..||'|| sqlerrm  );
--       end;

--         -------BOORANDO ssrmeet ---
--        begin
--             DELETE
--                FROM ssrmeet
--                WHERE SSRMEET_DATA_ORIGIN = 'SIU_SSB'
--                 AND  SSRMEET_CRN         =  VCRN
--                 AND  SSRMEET_VPDI_CODE   =  jump.seq_no;
--                 --dbms_output.put_line('borra  ssrmeet||' ||sql%rowcount );
--        exception when others then
--       --dbms_output.put_line('borra ssrmeet..||'|| sqlerrm  );
--       end;
--

         -----------BORRANDO sfbetrm -------

--       begin
--             DELETE
--                FROM sfrareg
--                where
--                  SFRAREG_DATA_ORIGIN ='WWW_SIU'
--                 AND SFRAREG_VPDI_CODE    = jump.seq_no
--                 AND SFRAREG_PIDM         = jump.PIDM
--                 AND SFRAREG_CRN          = VCRN
--                ;
--
--            --dbms_output.put_line('borra  sfrareg||' ||sql%rowcount );
--       exception when others then
--       --dbms_output.put_line('borra sfargfe..||'|| sqlerrm  );
--       end;

---------------------------------------cancela otra vez el serviciono lo no hizo el job automatico
--  UPDATE SVRSVPR v
--            SET  v.SVRSVPR_SRVS_CODE = 'CA',
--                 v.SVRSVPR_USER_ID   = 'WWW_CAN',
--                 v.SVRSVPR_ACTIVITY_DATE = SYSDATE,
--                 V.SVRSVPR_DATA_ORIGIN = 'BAJA_HOR'
--            WHERE 1=1
--             AND v.SVRSVPR_SRVS_CODE = 'AC'
--           --  AND (v.SVRSVPR_RECEPTION_DATE) <= sysdate - J.dias
--             and  V.SVRSVPR_SRVC_CODE  = 'NIVE'
--             and SVRSVPR_PROTOCOL_SEQ_NO = jump.seq_no;
     ----dbms_output.put_line('se actualiza el servicio'||jump.seq_no ||'-->>'|| sql%rowcount   );
END IF;

end loop;

exception when others then
null;

----dbms_output.put_line('borra gral..||'|| sqlerrm  );
end p_cancela_horario;
-----------------------------------------------------
FUNCTION F_cancela_horario_NIVE ( ppidm  in number, pmateria in varchar2 ) RETURN VARCHAR
IS

VCUENTA_ALUM      number:= 0;
vmateria          varchar2(14);
VCRN              varchar2(8);
nborra            number;
vperiodo          varchar2(16);
NUMEROD           NUMBER:=0;
V_SEQ_NO          NUMBER:=0;
VPROGRAMA         VARCHAR2(16);
VSALIDA           VARCHAR2(1000):='EXITO';
V_ERROR           VARCHAR2(1000);
vpparte           VARCHAR2(8);
VFINI2              VARCHAR2(18);
VFFIN2             VARCHAR2(18);

begin

IF  PPIDM IS NOT NULL THEN
 NUMEROD := 0;
    ----dbms_output.put_line('INICIO SII HAY PIDM  '|| NUMEROD);
 ELSE
 NUMEROD :=3;
 -----dbms_output.put_line('INICIO2 NOO HAY PIDM'|| NUMEROD);
END IF;

 FOR  jump in   (
                  select distinct datos.seq_no, datos.pidm , datos.code,
                            datos.fecha,datos.no_tran
                           ,hh.SVRSVAD_ADDL_DATA_CDE programa
                           ,datos.materia  materia
                     from (
                       SELECT distinct SVRSVPR_PROTOCOL_SEQ_NO seq_no, SVRSVPR_PIDM pidm , SVRSVPR_SRVC_CODE code,
                        SVRSVPR_RECEPTION_DATE fecha,SVRSVPR_ACCD_TRAN_NUMBER no_tran
                       -- , substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1 ) materia
                        ,SVRSVAD_ADDL_DATA_CDE  materia
                        FROM SVRSVPR p, SVRSVAD h
                        WHERE 1=1
                        AND p.SVRSVPR_SRVC_CODE   IN ( 'NIVE','NIVG' ,'NABA' )
                        AND p.SVRSVPR_SRVS_CODE   IN ('CA','AC')
                        AND h.SVRSVAD_PROTOCOL_SEQ_NO = p.SVRSVPR_PROTOCOL_SEQ_NO
                        AND  TRUNC(p.SVRSVPR_STATUS_DATE) >= '21/06/2019'  --ESTA FECHA ASI SE QUEDA ES EL DIA DE LA LIBERACION A PRODUCION WEB_SIU
                        and p.SVRSVPR_PIDM  =  nvl(ppidm, p.SVRSVPR_PIDM )
                        --AND substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1 ) = nvl(pmateria,substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1 )  ) --'L1C101'
                         AND h.SVRSVAD_ADDL_DATA_CDE   = nvl(pmateria,h.SVRSVAD_ADDL_DATA_CDE )
                        UNION
                        SELECT distinct SVRSVPR_PROTOCOL_SEQ_NO seq_no, SVRSVPR_PIDM pidm , SVRSVPR_SRVC_CODE code,
                        SVRSVPR_RECEPTION_DATE fecha,SVRSVPR_ACCD_TRAN_NUMBER no_tran
                         , h.SVRSVAD_ADDL_DATA_CDE   MATERIA
                        FROM SVRSVPR p, SVRSVAD h
                        WHERE     p.SVRSVPR_SRVC_CODE   IN ( 'EXTR','TISU')
                        AND p.SVRSVPR_SRVS_CODE   IN ('CA','AC')
                        AND h.SVRSVAD_PROTOCOL_SEQ_NO = p.SVRSVPR_PROTOCOL_SEQ_NO
                        AND  TRUNC(p.SVRSVPR_STATUS_DATE) >= '21/06/2019'  --ESTA FECHA ASI SE QUEDA ES EL DIA DE LA LIBERACION A PRODUCION WEB_SIU
                        and p.SVRSVPR_PIDM  =  nvl(ppidm, p.SVRSVPR_PIDM )
                        AND h.SVRSVAD_ADDL_DATA_CDE   = nvl(pmateria,h.SVRSVAD_ADDL_DATA_CDE )

                   )datos, SVRSVAD hh
                     where 1=1
                     and datos.SEQ_NO = hh.SVRSVAD_PROTOCOL_SEQ_NO
                       AND HH.SVRSVAD_ADDL_DATA_SEQ  = 1 )

       loop

         BEGIN
            select V.SVRSVPR_PROTOCOL_SEQ_NO
                 , case  when INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1) > 0 then
                      SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1)
                       else
                      SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10)-1 )
                  end as PPARTE
                 INTO V_SEQ_NO, vpparte
               from svrsvpr v,SVRSVAD VA
                    where SVRSVPR_SRVC_CODE = JUMP.code
                       AND  SVRSVPR_PIDM   = ppidm
                        AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  jump.seq_no
                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                       and va.SVRSVAD_ADDL_DATA_SEQ in (7) ; ------el valor 2 es para la parte de periodo
         EXCEPTION WHEN OTHERS THEN
           VPPARTE :='';
           V_SEQ_NO := 0;
           VSALIDA  := SQLERRM;
         END;

     --insert into twpasow( valor1,valor2, valor3, valor4, valor5, valor6 )
      --values('cancela horario NIG-1',JUMP.code,ppidm,jump.seq_no, V_SEQ_NO, vpparte );

                       --   --dbms_output.put_line('RECUPERA LA PARTE PERIODO DE NIVE::'|| vpparte);
         -------CON LA FECHAS BUSCAMOS EL PERIODO Y LO CALCULAMOS
        --  --dbms_output.put_line('RECUPERA los rangos del PERIODO DE NIVE::'|| VFINI2 || '--'||VFFIN2||'-'||JUMP.code||'-'||ppidm||'-'||jump.seq_no );

    IF JUMP.code = 'EXTR'   THEN
             Begin

             select SOBPTRM_TERM_CODE
                into Vperiodo
                from sobptrm
                where 1=1
                and  sobptrm_ptrm_code   = TRIM(vpparte)
                and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                AND TRUNC(SOBPTRM_START_DATE)  >=  TO_DATE(TRIM(VFINI2), 'DD/MM/YYYY')
                AND TRUNC(SOBPTRM_END_DATE)    <=  TO_DATE(TRIM(VFFIN2), 'DD/MM/YYYY')
                and substr(sobptrm_term_code,5,2) in (81,82,83)
                ;

            Exception
            When Others then
            v_error := 'No se Encontro el Periodo DE EXTR= ' ||vperiodo ||' y Parte de Periodo= '||VPparte ||sqlerrm;
            --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('INSRT_HORARIO_FECHAS_ERROORR22:: ',Ppidm, PSEQ_NO,vperiodo||'-'||VPparte, SUBSTR(vl_error,1,200), sysdate);
            VSALIDA  := SQLERRM;
            End;

      ELSIF  JUMP.code = 'TISU'   THEN

              Begin

             select SOBPTRM_TERM_CODE
                into Vperiodo
                from sobptrm
                where 1=1
                and  sobptrm_ptrm_code   = TRIM(vpparte)
                and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                AND TRUNC(SOBPTRM_START_DATE)  >=  TO_DATE(TRIM(VFINI2), 'DD/MM/YYYY')
                AND TRUNC(SOBPTRM_END_DATE)    <=  TO_DATE(TRIM(VFFIN2), 'DD/MM/YYYY')
                and substr(sobptrm_term_code,5,2) in (84,85,86)
                ;

            Exception
            When Others then
            v_error := 'No se Encontro el Periodo DE TISU= ' ||vperiodo ||' y Parte de Periodo= '||VPparte ||sqlerrm;
            --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3, VALOR4 ) VALUES ('INSRT_HORARIO_FECHAS_ERROORR_tisu:: ',Ppidm,VPparte||'-'||VFINI2||'-'||VFFIN2,   sysdate);
            VSALIDA  := SQLERRM;
            End;


    ELSIF  JUMP.code = 'NIVG'   THEN
     --insert into twpasow( valor1,valor2, valor3, valor4, valor5, valor6 )
      --values('cancela horario NIVG-2',JUMP.code,ppidm,jump.seq_no, V_SEQ_NO, vpparte );

           begin
                select substr(rango,1, instr(rango,'-TO-',1 )-1)as fecha_ini
                        ,substr(rango,instr(rango,'-TO-',1 )+4)as fecha_fin
                        INTO VFINI2, VFFIN2
                from (
                select   --substr(SVRSVAD_ADDL_DATA_DESC,33  )  rango
                         SVRSVAD_ADDL_DATA_DESC    rango
                         from svrsvpr v,SVRSVAD VA
                            where SVRSVPR_SRVC_CODE = JUMP.code
                            AND  SVRSVPR_PROTOCOL_SEQ_NO = jump.seq_no
                              AND  SVRSVPR_PIDM    = ppidm
                               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                               and va.SVRSVAD_ADDL_DATA_SEQ = '7'
                               ) ;

          EXCEPTION WHEN OTHERS  THEN
            VFINI2:= TRUNC(SYSDATE);
            VFFIN2 := TRUNC(SYSDATE)+7;
          END;

      --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 )
      --VALUES ('CANCELA_HORARIO_FECHAS_NIVG_3:: ',Ppidm,  jump.seq_no,VFINI2||'-'||VFFIN2, SUBSTR(VSALIDA,1,100), sysdate);




             Begin

             select SOBPTRM_TERM_CODE
                into Vperiodo
                from sobptrm
                where 1=1
                and  sobptrm_ptrm_code   = TRIM(vpparte)
                AND TRUNC(SOBPTRM_START_DATE) >=  TO_CHAR(to_date(VFINI2,'MM/dd/YYYY') , 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH')
                AND TRUNC(SOBPTRM_END_DATE)  <=    TO_CHAR(to_date(VFFIN2,'MM/dd/YYYY') , 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH')
                 and  substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                ;

            Exception
            When Others then
              BEGIN
                    select DISTINCT SOBPTRM_TERM_CODE
                        into Vperiodo
                        from sobptrm
                        where 1=1
                        and  sobptrm_ptrm_code   = TRIM(vpparte)
                        AND TRUNC(SOBPTRM_START_DATE) >=  TO_CHAR(to_date(VFINI2,'MM/dd/YYYY') , 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH')
                        --AND TRUNC(SOBPTRM_END_DATE)  <=    TO_CHAR(to_date(VFFIN2,'MM/dd/YYYY') , 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH')
                         and  substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2) ;

               EXCEPTION WHEN OTHERS THEN
                 --   vl_error :=  sqlerrm;
                  Vperiodo     := '';
                    VSALIDA  := SQLERRM;
                END;

            End;

            --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 )
            --VALUES ('CANCELA_HORARIO_PERIODO_:: ',Ppidm,  jump.seq_no,VFINI2||'-'||Vperiodo, SUBSTR(VSALIDA,1,100), sysdate);

    ELSE --- ESTO ES NIVE
               begin
                select substr(rango,1, instr(rango,'-AL-',1 )-1)as fecha_ini
                        ,substr(rango,instr(rango,'-AL-',1 )+4)as fecha_fin
                        INTO VFINI2, VFFIN2
                from (
                select   --substr(SVRSVAD_ADDL_DATA_DESC,33  )  rango
                         SVRSVAD_ADDL_DATA_DESC    rango
                         from svrsvpr v,SVRSVAD VA
                            where SVRSVPR_SRVC_CODE = JUMP.code
                            AND  SVRSVPR_PROTOCOL_SEQ_NO = jump.seq_no
                              AND  SVRSVPR_PIDM    = ppidm
                               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                               and va.SVRSVAD_ADDL_DATA_SEQ = '7'
                               ) ;

          EXCEPTION WHEN OTHERS  THEN
            VFINI2:= TRUNC(SYSDATE);
            VFFIN2 := TRUNC(SYSDATE)+7;
          END;


                Begin

             select SOBPTRM_TERM_CODE
                into Vperiodo
                from sobptrm
                where 1=1
                and  sobptrm_ptrm_code   = TRIM(vpparte)
                and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                AND TRUNC(SOBPTRM_START_DATE)  >=  TO_DATE(TRIM(VFINI2), 'DD/MM/YYYY')
                AND TRUNC(SOBPTRM_END_DATE)    <=  TO_DATE(TRIM(VFFIN2), 'DD/MM/YYYY');

            Exception
            When Others then
            v_error := 'No se Encontro el Periodo DE NIVE= ' ||vperiodo ||' y Parte de Periodo= '||VPparte ||sqlerrm;
            --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3, VALOR4 ) VALUES ('INSRT_HORARIO_FECHAS_ERROORR_tisu:: ',Ppidm,VPparte||'-'||VFINI2||'-'||VFFIN2,   sysdate);
            VSALIDA  := SQLERRM;
            End;

      END IF;

        ----dbms_output.put_line('RECUPERA NUEVO PERIODO DE NIVE::'||vperiodo||'-'||vpparte || VFINI2 ||'-'||VFFIN2 );


--   INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8)
--   VALUES ('fCANCELA_NIVE _inicio  ',jump.pidm,jump.materia,vperiodo, JUMP.seq_no,vpparte,VFINI2,VFFIN2  ); COMMIT;
--    --dbms_output.put_line('INICIO 0 regresa materia:.'||jump.seq_no||'-'|| jump.pidm||'-mater--'|| pmateria||'--'||vperiodo||'-crn-'||VCRN);
         ---------------------------------------obtiene el periodo-----------
--         begin
--            select  SVRSVAD_ADDL_DATA_CDE periodo
--                INTO vperiodo
--                from SVRSVAD
--                where SVRSVAD_PROTOCOL_SEQ_NO = jump.seq_no
--                and   SVRSVAD_ADDL_DATA_SEQ = 6;
--         exception when others then
--         vperiodo  := '';
--         VSALIDA:= SQLERRM;
--         end;
         ----dbms_output.put_line('INICIO 1 regresa periodo:.'||jump.seq_no||'-'|| jump.pidm||'-'|| jump.materia||'-perid-'||vperiodo||'-crn-'||VCRN);
------------------------------------busca el CRN con l materia------------------------
        begin
            select SFRSTCR_CRN
                 INTO VCRN
                 FROM SFRSTCR f, ssbsect b
                   WHERE     F.SFRSTCR_CRN     = B.SSBSECT_CRN
                      AND F.SFRSTCR_TERM_CODE  = B.SSBSECT_TERM_CODE
                      AND F.SFRSTCR_PIDM       = jump.pidm
                      and F.SFRSTCR_TERM_CODE  = vperiodo
                      and f.SFRSTCR_STRD_SEQNO  = JUMP.seq_no
                      AND SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB =  jump.materia;
          exception when others then
         VCRN  := '';
         VSALIDA:= SQLERRM;
           ---INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3, VALOR4, VALOR5)  VALUES ('fCANCELA_NIVE',jump.pidm,jump.materia,vperiodo, V_ERROR); COMMIT;
         end;
                      --and SFRSTCR_RSTS_CODE  = 'RE'  ;
         ----dbms_output.put_line('INICIO 2 regresa CRN:.'||jump.seq_no||'-'|| jump.pidm||'-'|| jump.materia||'--'||vperiodo||'-crn-'||VCRN);
--        INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3, VALOR4, VALOR5)  VALUES ('fCANCELA_NIVE',jump.pidm,jump.materia,vperiodo, VCRN); COMMIT;
---------------------1.- borra tabla sfrstcr que es hija---  cuenta si hay mas de un alumno en el mismo crn
       BEGIN
            SELECT COUNT(*)
            INTO  VCUENTA_ALUM
            FROM sfrstcr
            where 1=1
            --SFRSTCR_DATA_ORIGIN ='SIU_SSB'
            and   SFRSTCR_STRD_SEQNO   = jump.seq_no
            and   SFRSTCR_TERM_CODE   = vperiodo
            and  SFRSTCR_PIDM         = jump.pidm
            AND  SFRSTCR_CRN          = VCRN
            and SFRSTCR_RSTS_CODE     = 'RE'
            ;
       EXCEPTION WHEN OTHERS THEN
       VSALIDA := SQLERRM;
         --INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3, VALOR4, VALOR5)  VALUES ('ERROR CUENTA_MATERIAS',jump.pidm,jump.materia,vperiodo, V_ERROR); COMMIT;
       END;

----------------si existe cuenta mas de uno entonces no borra el s
 ----dbms_output.put_line('antes de entrar >>>:.'||jump.seq_no||'-'|| jump.pidm||'-'|| jump.materia||'--'||vperiodo||'-'|| vcrn );
IF VCUENTA_ALUM >= 1  THEN
NULL;
----dbms_output.put_line('DENTRO de alumno> 1  >>>:.'||jump.seq_no||'-'|| jump.pidm||'-'|| jump.materia||'--'||vperiodo||'-'|| vcrn );
       -----------------borra el maestro primero-------------
/*
    -------------BORRANDO SIRASGN-----
         begin
             DELETE
                FROM sirasgn ss
               where  1=1
                    and SS.SIRASGN_TERM_CODE  = vperiodo
                    and ss.SIRASGN_CRN           =VCRN
                    AND  ss.SIRASGN_VPDI_CODE   =  jump.seq_no ;

                 --dbms_output.put_line('borra  sirasgn||' ||sql%rowcount );
         exception when others then
       --dbms_output.put_line('borra sirasgn..||'|| sqlerrm  );
       VSALIDA := sqlerrm;
       end;


     -------HACE EL BORRADO---ssbsect----
      begin
         DELETE
            FROM ssbsect st
              WHERE st.ssbsect_DATA_ORIGIN ='WWW_SIU'
               AND  st.SSBSECT_CRN         = VCRN
               and  ST.SSBSECT_TERM_CODE   = vperiodo
               AND  st.SSBSECT_VPDI_CODE   = jump.seq_no;
               --dbms_output.put_line('borra  ssbsect||' ||sql%rowcount );
       exception when others then
       --dbms_output.put_line('borra ssbsect..||'|| sqlerrm  );
       VSALIDA := sqlerrm;
       end;
    */
            -----------hay que actualizar   poner en DD -------------
      begin


              UPDATE sfrstcr
              SET   SFRSTCR_RSTS_CODE = 'DD',
                    SFRSTCR_DATA_ORIGIN ='WWW_CAN' ,
                    SFRSTCR_ACTIVITY_DATE  = sysdate,
                    SFRSTCR_RSTS_DATE      = sysdate
                 where 1=1
                  AND SFRSTCR_PIDM        = jump.PIDM
                  AND SFRSTCR_CRN         = VCRN
                  AND SFRSTCR_STRD_SEQNO  = jump.seq_no
                  and SFRSTCR_TERM_CODE   = vperiodo
                 ;


            ----dbms_output.put_line('borra  sfrstcr||' ||sql%rowcount );
       exception when others then
       ----dbms_output.put_line('borra sfrtscr..||'|| sqlerrm  );
       VSALIDA := sqlerrm;

       end;
       --INSERT INTO TWPASOW( VALOR1,VALOR2,VALOR3, VALOR4, VALOR5) VALUES('CANCELA HORARIO_SIIIIIII ', ppidm, pmateria, VSALIDA, SYSDATE  ) ;

    ELSE
  --   --dbms_output.put_line('nO SE ENCONTRO EL HORARIO'  );
            ----MANDA ESTE EXITO QUIERE DECIR QUE NO HUBO NADA QUE CANCELAR Y MANDA EXITO
           VSALIDA := 'EXITO' ;

    --    INSERT INTO TWPASOW( VALOR1,VALOR2,VALOR3, VALOR4, VALOR5) VALUES('CANCELA HORARIO_SIN_EXISTIR ', ppidm, pmateria, VSALIDA, SYSDATE  ) ;
      --  COMMIT;

END IF;
COMMIT;

end loop;

IF VSALIDA  ='EXITO' THEN
RETURN VSALIDA;
ELSE

RETURN  VSALIDA;
END IF;


--INSERT INTO TWPASOW( VALOR1,VALOR2,VALOR3, VALOR4, VALOR5) VALUES('CANCELA HORARIO ALL ', ppidm, pmateria, VSALIDA, SYSDATE  ) ;
--COMMIT;

exception when others then
null;
VSALIDA := sqlerrm;

RETURN VSALIDA;

----dbms_output.put_line('borra gral..||'|| sqlerrm  );
end F_cancela_horario_NIVE;

FUNCTION F_MATERIA_NIVE (PPIDM NUMBER, pprogram varchar2, PCODE varchar2 ) Return VARCHAR2  IS

  CONTADOR   NUMBER;
 VSALIDA    varchar2(300);
 VDESC       varchar2(30);
 VDESC2     NUMBER:=0;
 VCOSTO     NUMBER;
 VCOSTO2    NUMBER;
 vrango1    number;
 vrango2    number;
 vparam_mate    NUMBER;
 VTALLERES    NUMBER:=0;
 vcampus      varchar2(4);
 VFUNCION     varchar2(40);
 PACAMPUS     VARCHAR2(4);
 TERMATERIAS   VARCHAR2(10);
vvalida_eng  VARCHAR2(1):='N';
VVALIDA0  VARCHAR2(100);
VMAT_BACH    VARCHAR2(1);

--PCODE        VARCHAR2(5):= 'TISU';  ---ESTE VA SER UN PARAMETRO DE LA FUNCION PEDIR A KEKO QUE LA INCLUYA
-- se realiza un cambio para identificar de acuerdo al campus que periodo tiene en SHRGRDE y ver si la calificacion es acreditada o reprobada glovicx 17/01/022
-- SE AGREGA LA FUNCIONALIDAD  de NABA  es la nivelación de bachillerato glovicx 02.05.2024 

BEGIN

         DELETE FROM extraor2
         WHERE  PIDM = PPIDM ;

--------------------aqui determinamos si el campus es unica o es utel glovicx 23/11/2020
begin
select CAMPUS
   into vcampus
 from tztprog
   where pidm  = PPIDM
   and programa = pprogram
 ;

 exception when others then
  vcampus := null;

 end;
---------OBTENGO EL PARAMETRO DE LAS OTRAS UNIVERSADEES
BEGIN

   select  DISTINCT ZSTPARA_PARAM_VALOR AS FUNCION, ZSTPARA_PARAM_ID
       INTO VFUNCION  ,  PACAMPUS
         from  ZSTPARA
           where ZSTPARA_MAPA_ID = 'NIVE_FUNCION'
            AND ZSTPARA_PARAM_ID  = vcampus
           ;


 exception when others then
  VFUNCION := null;
  PACAMPUS := NULL;
 end;


-- nuevo aqui buscamos el nuevo valor del periodo en shgrade glovicx 17/01/022

      begin
         select distinct ZSTPARA_PARAM_DESC
           INTO TERMATERIAS
        from ZSTPARA
        where 1=1
        and ZSTPARA_MAPA_ID = 'ESC_SHAGRD'
        and ZSTPARA_PARAM_ID = substr(F_GetSpridenID(PPIDM),1,2);
      exception when others then
          TERMATERIAS := null;

       end;


 begin

        select DISTINCT  'Y'
          INTO  vvalida_eng
            from zstpara
             where 1=1
              and ZSTPARA_PARAM_ID = vcampus
              and ZSTPARA_MAPA_ID = 'COES_INGLES';

      exception when others then
       vvalida_eng :=  'N';
      end;



--insert into twpaso ( valor1, valor2 )
 --     values('paso universidad fuera materisa',VSALIDA );

------aqui evalua a donde entra para sacar las materias-- glovicx 23/11/20
--PRIMERO VALIDAMOS SI EL CAMPUES ES EN INGLES O ESPAÑOL  GLOVICX 29.09.022
IF vvalida_eng = 'Y' THEN
NULL;
  VSALIDA :=   BANINST1.PKG_SERV_SIU.F_MATERIA_NIVE_INGLES (PPIDM , pprogram  );

RETURN (VSALIDA);

ELSIF vcampus = PACAMPUS  THEN

NULL;
-----MANDO A EJECUTAR POR FUERA EL PROCESO QUE INSERTA LAS MATERIAS Y SU LOGICA POR UNIVERSIDAD

  --VSALIDA := VFUNCION (PPIDM, pprogram ) ;
    IF  PCODE = 'EXTR' THEN
--  execute immediate 'call '||VFUNCION(PPIDM, pprogram ) ||' into :lv_ret_cd' using out VSALIDA;
     VSALIDA :=   BANINST1.PKG_SERV_SIU.F_MATERIA_NIVE_UNI(PPIDM, pprogram ) ;
   --  --dbms_output.PUT_LINE('INSIDE EXECUTE after'|| VSALIDA);
    -- insert into twpaso ( valor1, valor2 )
     -- values('paso universidad UNICA  EXTRA',VSALIDA );

     ELSIF  PCODE = 'TISU' THEN
         VSALIDA :=  BANINST1.PKG_SERV_SIU.F_MATERIA_TISU_UNI(PPIDM, pprogram ) ;
    --  insert into twpaso ( valor1, valor2 )
     -- values('paso universidad UNICA TISUU',VSALIDA );
        NULL;
        --AQUI VA LA FUNCION F_MATERIA_TISU_UNI
     END IF;



  ELSE

FOR JUMP IN (
        select distinct datos.materia MATERIA, --||'|'||costo,
        rpad(cc.SCRSYLN_LONG_COURSE_TITLE,40,'-') NOMBRE_MATERIA, --||' $ '|| costo,
        datos.programa AS PROGRAMA,
        -- nvl(datos.costo, 000)as costo,
        DATOS.PIDM AS PIDM
        ,datos.nivel as nivel
        ,datos.sp
        ,DATOS.CAMPUS
        from (
                SELECT (qq.ssbsect_subj_code || qq.ssbsect_crse_numb) materia
                --( select M.SZTMACO_MATPADRE from sztmaco m where M.SZTMACO_MATHIJO = qq.SSBSECT_SUBJ_CODE || qq.SSBSECT_CRSE_NUMB) materia,
                , CASE
                WHEN qq.ssbsect_seq_numb IS NULL
                THEN
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                ELSE
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                END nombre_materia,
                so.SORLCUR_PROGRAM as programa
                ,SO.SORLCUR_PIDM as pidm
                ,SO.SORLCUR_LEVL_CODE AS NIVEL
                ,'1' FINAL
                ,cr.SFRSTCR_STSP_KEY_SEQUENCE as Sp
                ,SO.SORLCUR_CAMP_CODE  AS CAMPUS
                FROM ssbsect qq, sfrstcr cr, shrgrde sh, sorlcur so, stvterm x, spriden sp
                ,(SELECT ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_ID, ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION' ) cos
                WHERE 1=1
                AND cr.sfrstcr_pidm = PPIDM
                AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                AND cr.sfrstcr_crn = qq.ssbsect_crn
                AND sh.shrgrde_code = cr.SFRSTCR_GRDE_CODE
                and sh.SHRGRDE_LEVL_CODE = cr.SFRSTCR_LEVL_CODE
                AND sh.shrgrde_passed_ind = 'N'
                and cr.SFRSTCR_GRDE_CODE is not null
                AND so.SORLCUR_LMOD_CODE = 'LEARNER'
                AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS', 'BA')
                AND sh.shrgrde_levl_code = so.SORLCUR_LEVL_CODE
                AND cr.sfrstcr_pidm = so.sorlcur_pidm
                And so.sorlcur_program = pprogram
                And cr.SFRSTCR_STSP_KEY_SEQUENCE = so.SORLCUR_KEY_SEQNO
                AND so.sorlcur_term_code = x.stvterm_code
                AND sp.spriden_change_ind IS NULL
                and cr.sfrstcr_pidm = SP.SPRIDEN_PIDM
                and cos.ZSTPARA_PARAM_DESC(+) = qq.ssbsect_subj_code || qq.ssbsect_crse_numb
                minus
                SELECT qq.ssbsect_subj_code || qq.ssbsect_crse_numb materia
                , CASE
                WHEN qq.ssbsect_seq_numb IS NULL
                THEN
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                ELSE
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                END nombre_materia,
                so.SORLCUR_PROGRAM as programa
                ,SO.SORLCUR_PIDM as pidm
                ,SO.SORLCUR_LEVL_CODE AS NIVEL
                ,'2' FINAL
                ,cr.SFRSTCR_STSP_KEY_SEQUENCE as Sp
                  ,SO.SORLCUR_CAMP_CODE  AS CAMPUS
                FROM ssbsect qq, sfrstcr cr, sorlcur so, stvterm x, spriden sp
                ,(SELECT ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_ID, ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION' ) cos
                WHERE 1=1
                AND cr.sfrstcr_pidm = PPIDM --fget_pidm('010075696')
                AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                AND cr.sfrstcr_crn = qq.ssbsect_crn
                and cr.SFRSTCR_GRDE_CODE is null
                and cr.SFRSTCR_RSTS_CODE = 'RE'
                AND so.SORLCUR_LMOD_CODE = 'LEARNER'
                AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS', 'BA')
                AND cr.sfrstcr_pidm = so.sorlcur_pidm
                And so.sorlcur_program = pprogram
                AND so.sorlcur_term_code = x.stvterm_code
                AND sp.spriden_change_ind IS NULL
                and cr.sfrstcr_pidm = SP.SPRIDEN_PIDM
                And cr.SFRSTCR_STSP_KEY_SEQUENCE = so.SORLCUR_KEY_SEQNO
                and cos.ZSTPARA_PARAM_DESC(+) = qq.ssbsect_subj_code || qq.ssbsect_crse_numb
                ) datos
               , SCRSYLN cc
                where 1=1
                and SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB = datos.materia
                --AND SCBCRSE_CSTA_CODE = 'A'
                AND NOT EXISTS
                (SELECT 1
                FROM SVRSVPR p, SVRSVAD h
                WHERE p.SVRSVPR_SRVC_CODE in ('NIVE','NABA')
                AND P.SVRSVPR_PIDM = PPIDM --fget_pidm('010075696')
                AND ( p.SVRSVPR_SRVS_CODE in ('AC')--se quito la validacion de "PA" a peticion de Fernando el dia 05/12/2019
                    OR p.SVRSVPR_STEP_COMMENT != 'NIVE_CERO'    -- se agrego esta validacion para nivecero glovicx 03.11.2023
                     )
                AND h.SVRSVAD_PROTOCOL_SEQ_NO = p.SVRSVPR_PROTOCOL_SEQ_NO
                --AND h.SVRSVAD_ADDL_DATA_CDE = datos.materia||'|'||costo) ----con este filtra que no se solicite una materia que ya fue solicitada
                --AND substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1) = datos.materia)
                and h.SVRSVAD_ADDL_DATA_CDE = datos.materia)
                and datos.materia NOT in ( select SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB
                        FROM ssbsect qq, sfrstcr cr, shrgrde SH
                        WHERE 1=1
                        AND cr.sfrstcr_pidm = PPIDM --fget_pidm('010075696')
                        AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                        AND cr.sfrstcr_crn = qq.ssbsect_crn
                         and  SHRGRDE_TERM_CODE_EFFECTIVE   = TERMATERIAS
                        and ( cr.SFRSTCR_GRDE_CODE in ('6.0','7.0','8.0','9.0','10.0')
                        or cr.SFRSTCR_GRDE_CODE is null )
                        AND CR.SFRSTCR_GRDE_CODE = SH.SHRGRDE_CODE
                        AND CR.SFRSTCR_LEVL_CODE = SH.SHRGRDE_LEVL_CODE
                        AND shrgrde_passed_ind = 'Y' ---------ESTO DIVIDE LAS CALIFICACIONES EN PASADAS Y REPROBADAS PARA LI Y MA.MS
                        and cr.sfrstcr_term_code = (select max(cr.sfrstcr_term_code ) from sfrstcr c2 where cr.sfrstcr_pidm = c2.sfrstcr_pidm ))
                And (DATOS.PIDM, datos.materia ) not in (select a.SFRSTCR_PIDM, b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB
                                                                                            from sfrstcr a, ssbsect b
                                                                                            Where  a.SFRSTCR_TERM_CODE =  b.SSBSECT_TERM_CODE
                                                                                            And a.SFRSTCR_CRN = b.SSBSECT_CRN
                                                                                            And a.SFRSTCR_RSTS_CODE = 'RE'
                                                                                            and ( a.SFRSTCR_GRDE_CODE in (select SHRGRDE_CODE
                                                                                                                                from SHRGRDE
                                                                                                                                Where SHRGRDE_LEVL_CODE = a.SFRSTCR_LEVL_CODE
                                                                                                                                and  SHRGRDE_TERM_CODE_EFFECTIVE   = TERMATERIAS
                                                                                                                                And SHRGRDE_PASSED_IND ='Y')
                                                                                                 or a.SFRSTCR_GRDE_CODE is null ))
                ORDER BY 1,6
        ) LOOP
         ---------------------se obtiene el porcentaje de avance del alumno para calcular el precio
        BEGIN
           SELECT ROUND(nvl(SZTHITA_AVANCE,0))
              INTO VDESC2
                FROM SZTHITA ZT
                WHERE ZT.SZTHITA_PIDM = JUMP.PIDM
                AND    ZT.SZTHITA_LEVL  = jump.nivel
                AND   ZT.SZTHITA_PROG   = JUMP.PROGRAMA  ;
                ----dbms_output.PUT_LINE('SALIDA AVANCE HITA  '|| VDESC2);
       EXCEPTION WHEN OTHERS THEN
        VDESC2 :=0;
                BEGIN
                   SELECT ROUND(BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 ( JUMP.PIDM, JUMP.PROGRAMA ))
                          INTO VDESC2
                     FROM DUAL;

                  --   --dbms_output.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
                  EXCEPTION WHEN OTHERS THEN
                   VDESC2 :=0;
                  END;
      END;
      
       --DBMS_OUTPUT.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
          ------ VALIDAMOS SI ESTA PRENDIDO O APAGADO EL COSTO CERO PARA NIVELACIONES 
          ----- SE VALIDO EL NUEVO PARAMETRIZADOR SI ES TRUE ENTONCES 
        --IF PARA ES TRU ENTONCES      
        begin  
          VVALIDA0 := PKG_SERV_SIU.F_NIVE_CERO(JUMP.PIDM , PCODE , JUMP.PROGRAMA , JUMP.MATERIA  );
         exception when others then
          vsalida := sqlerrm;
          
           --DBMS_OUTPUT.PUT_LINE('errorn en funcion NIVECERO:: '||JUMP.MATERIA||'-'|| vsalida);
         end;
         
         --DBMS_OUTPUT.PUT_LINE('despues de NIVECERO:: '||JUMP.MATERIA||'-'|| vsalida);
        -- insert into twpasow (valor1,valor2,valor3,valor4,valor5)
         --  values(JUMP.PIDM , PCODE , JUMP.PROGRAMA , JUMP.MATERIA, sysdate );
         
       -- ELSE
       -- NULL
       -- END IF; 
       --DBMS_OUTPUT.PUT_LINE('SALIDA funcion nive cero:: '|| VVALIDA0);
       
    IF VVALIDA0 = 'EXITO'  THEN 
        VCOSTO2 := 0;
        
    ELSE
      
      
      -------------------OBTIENE EL COSTO------------
      BEGIN
                ---se cambia la forma de calcular el costo nuevo requerimento 07/03/2022  de tavito
                 /*  select ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                      INTO VDESC, VCOSTO
                    from  ZSTPARA
                    where ZSTPARA_MAPA_ID = 'PORCENTAJE_NIVE'
                  --  and  ZSTPARA_PARAM_ID = jump.nivel
                    and  substr(ZSTPARA_PARAM_ID,1,2) =  jump.nivel -- 'LI'
                    and  substr(ZSTPARA_PARAM_ID,4) =  jump.CAMPUS -- 'UTL'
                    and ROUND(VDESC2) between substr(ZSTPARA_PARAM_DESC,1,instr(ZSTPARA_PARAM_DESC,',',1)-1)
                    and  substr(ZSTPARA_PARAM_DESC,instr(ZSTPARA_PARAM_DESC,',',1)+1)
                    ; */
                    select distinct SZT_PRECIO
                       into VCOSTO
                        from sztnipr
                        where 1=1
                        and SZT_NIVEL =  jump.nivel
                        and SZT_CAMPUS  =  jump.CAMPUS
                            and SZT_PRECIO  > 0  -----SE AGREGO ESTA LINEA PARA QUE NO CHOQUE CON COSTO CERO
                        and ROUND(VDESC2) between ( SZT_MINIMO ) and (SZT_MAXIMO )
                        and substr(SZT_CODE,1,2) = substr(F_GetSpridenID(JUMP.PIDM),1,2);


                    
        EXCEPTION WHEN OTHERS THEN
        -- dbms_output.PUT_LINE('error  COSTOS_1  '|| sqlerrm  ||'-'|| VCOSTO);
          VCOSTO:= 0;
      END;


          IF  vcosto = 0  then
            begin
              SELECT  distinct nvl(MAX (svrrsso_serv_amount), 0)
                  INTO  VCOSTO2
                   FROM svrrsso a , tbbdetc tt,SVRRSRV r
                    WHERE  1=1
                      AND A.SVRRSSO_SRVC_CODE     = R.SVRRSRV_SRVC_CODE
                      and A.SVRRSSO_RSRV_SEQ_NO = R.SVRRSRV_SEQ_NO
                      and  a.svrrsso_srvc_code in ('NIVE', 'NABA')
                      and  a.SVRRSSO_DETL_CODE = tt.TBBDETC_DETAIL_CODE
                      AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(JUMP.PIDM),1,2)
                         --and  tt.TBBDETC_TAXT_CODE = jump.nivel
                      and   r.SVRRSRV_LEVL_CODE =  jump.nivel
                         ;
              EXCEPTION when others then
                    VCOSTO2 := 0;
              end;

             ELSE
             VCOSTO2 := vcosto;
          end if;

          ------excepcion especial para que los talleres los cobre de 2100 segun el parametrizador-----
         begin
           select ZSTPARA_PARAM_VALOR
             into vparam_mate
           FROM ZSTPARA
              WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION'
               and   ZSTPARA_PARAM_ID  = JUMP.MATERIA
               AND ZSTPARA_PARAM_DESC  = JUMP.CAMPUS
            ;

          exception when others then
             vparam_mate := VCOSTO2;
             --dbms_output.PUT_LINE('SALIDA parmetrzi mate_nive  '|| JUMP.MATERIA ||'-'|| JUMP.CAMPUS);
          end;

          if vparam_mate > 0 then
            VCOSTO2 := vparam_mate;
            else
               VCOSTO2 := VCOSTO2 ;
          end if;
          
    END IF;
    
    IF pcode = 'NABA' then  
         --regla para bachillerato si la materia reprobada esta en este agrupador entonces si la muestra en combo glovicx 02.05.2024
        BEGIN
               
            SELECT 'Y'
               INTO VMAT_BACH
                    FROM ZSTPARA
                    WHERE 1=1
                    and ZSTPARA_MAPA_ID = 'NIV_BACH_UVE'
                    and  ZSTPARA_PARAM_ID = JUMP.MATERIA;
                    
         EXCEPTION WHEN OTHERS THEN
            VMAT_BACH := 'N';
         END;
     end if;     
         -------------------
     ----dbms_output.put_line('salida materias::  '||JUMP.MATERIA||'-'||JUMP.NOMBRE_MATERIA||'-'||JUMP.PROGRAMA||'-'||VCOSTO2||'-'||JUMP.PIDM||'--'||jump.nivel );
      ----se agrega la validacion para EXCLUIR LAS MATERIAS DE LOS TALLERES A TRAVES DEL PARAMETRIZADOR LO HIZO FERNANDO
      -----19/03/2020  GLOVICX
           BEGIN

                select 1--* --ZSTPARA_PARAM_VALOR as alum_sin_restriccio
                  INTO VTALLERES
                 from zstpara z
                  where 1=1
                      and Z.ZSTPARA_MAPA_ID  = 'SIN_MAT_MOODLE'
                      and z.ZSTPARA_PARAM_ID = JUMP.MATERIA
                      ;
           EXCEPTION WHEN OTHERS THEN
             VTALLERES := 0;
           END;
           
          -- dbms_output.put_line('antes del insert extraor2 '|| VTALLERES||'-'|| VMAT_BACH  );
           ---SI EL VALOR DE VTALLERES ES UNO QUIERE DECIR QUE SE DEBE DE EXCLUIR  NO INSERTAR
           IF VTALLERES >= 1 OR VMAT_BACH = 'N' THEN
             NULL; --AQUI LO EXCLUYO
           ELSE

                         INSERT INTO extraor2 ---------------se cambio este queri es el que presenta las materias reprobadas en el SSB -- VIC-- 28.06.2018
                          VALUES ( JUMP.MATERIA||'|'||VCOSTO2,
                                   JUMP.NOMBRE_MATERIA||' $ '||TO_CHAR(VCOSTO2,'999,999.00' ),
                                   JUMP.PROGRAMA,
                                   VCOSTO2,
                                   JUMP.PIDM);
                 COMMIT;
            END IF;

   END LOOP;

   END IF; --AQUI CIERRA EL IF DE UNICA--
    VSALIDA   := 'EXITO';
    RETURN   VSALIDA;

Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error :'||sqlerrm;
    -- insert into twpasow(valor1, valor2, valor3, valor6)
    ---   values( 'eroorro en fmateria_nive gral ',TO_CHAR(VCOSTO2,'L99G999D99MI' ),PPIDM,VSALIDA  );
    RETURN (VSALIDA);

END F_MATERIA_NIVE;

function F_update_code_tbra return varchar2
is


------------------CORRIGE LOS CODIGOS QUE CAYERON MAL EN LAS CACELACIONES---
 vcodigo_dtl  VARCHAR2(5);
 vdescrp    VARCHAR2(50);
VPCODE      VARCHAR2(4);

CURSOR C_ALUMNO IS
select F_GetSpridenID(TBRACCD_PIDM) MATRICULA,
TBRACCD_PIDM  PIDM ,
TBRACCD_TRAN_NUMBER  TRANUM,
TBRACCD_TRAN_NUMBER_PAID TRAN_PAID,
TBRACCD_CROSSREF_NUMBER NO_SEQ,
TBRACCD_DOCUMENT_NUMBER DOCU
from tbraccd
where 1=1
AND TBRACCD_DOCUMENT_NUMBER !='WCANCE'  --no toma el original osea el cargo
AND TBRACCD_DETAIL_CODE  !='01OA'        -- no toma el descuento si esque lo tiene para colf
--and TBRACCD_PIDM   = 26856
--and TBRACCD_TRAN_NUMBER  = 118
and (TBRACCD_CROSSREF_NUMBER) in ( select TBRACCD_CROSSREF_NUMBER
                                    from tbraccd
                                    where TBRACCD_USER LIKE '%WWW_CAN%'
                                    AND TRUNC(TBRACCD_ACTIVITY_DATE) >= '01/08/2019'---APARTIR DE ESTA FECHA SE LIBERO
                                    and TBRACCD_DETAIL_CODE = '01B4'  )
order by TBRACCD_CROSSREF_NUMBER, TBRACCD_TRAN_NUMBER   ;

begin

BEGIN

FOR JUMP IN C_ALUMNO LOOP

BEGIN
select SVRSVPR_SRVC_CODE
    INTO VPCODE
    from svrsvpr v
    where 1=1
      AND  SVRSVPR_PROTOCOL_SEQ_NO = JUMP.NO_SEQ
      AND  SVRSVPR_PIDM    = JUMP.PIDM;
EXCEPTION WHEN OTHERS THEN
VPCODE   := '';
END;


BEGIN
select DISTINCT TBBDETC_DETAIL_CODE code_dtl, tbbdetc_desc descp
    INTO    vcodigo_dtl, vdescrp
     FROM TBBDETC T , SZTCCAN ZC
     where 1=1
     and  TBBDETC_TYPE_IND   = 'P'
     and  TBBDETC_DCAT_CODE  = 'CAN'
    -- and TBBDETC_TAXT_CODE   = 'GN'
     AND SUBSTR(T.TBBDETC_DETAIL_CODE,3,2)  = SUBSTR(ZC.SZTCCAN_CODE,3,2)
     AND ZC.SZTCCAN_CODE_SERV  = VPCODE
     and   substr(TBBDETC_DETAIL_CODE,1,2)  = SUBSTR(JUMP.MATRICULA,1,2);
EXCEPTION WHEN OTHERS THEN
 vcodigo_dtl := '';
 vdescrp  := '';
END;


----dbms_output.PUT_LINE('REGS. PARA ACTUALIZAR EN TBRA:  '|| jump.matricula||'--'||VPCODE||'--'|| JUMP.PIDM ||'-'||JUMP.TRANUM||'--'||JUMP.NO_SEQ||'--'|| vcodigo_dtl||'--'|| vdescrp  );

UPDATE tbraccd
SET TBRACCD_DETAIL_CODE = vcodigo_dtl,
    TBRACCD_DESC      =   vdescrp
 WHERE 1=1
  AND TBRACCD_PIDM = JUMP.PIDM
  AND TBRACCD_TRAN_NUMBER =  JUMP.TRANUM
  AND TBRACCD_CROSSREF_NUMBER = JUMP.NO_SEQ
    ;
 COMMIT;
END LOOP;

EXCEPTION WHEN OTHERS THEN
----dbms_output.PUT_LINE(' ERROOR EN AJUSTE DE CODIGOS DE CANCELACION:  '|| SQLERRM);
null;
END;

end F_update_code_tbra;


FUNCTION F_CAN_JOB2  RETURN VARCHAR2  IS
/*    ESTE PROCESO SE EJECUTA EN EL PROCESO DE CANCELA JOB Y BARRE TODO LOS SERVICIOS QUE SE HAYAN HEHCO DESDE AFUERA DEL SSB_SIU Y QUE NO SE
PAGARON Y HAY QUE CANCELAR. 11 SEPT 2019.

*/

Vexiste     number:=0;
PPCODE2     varchar2(6);
PPCODE      varchar2(6);
PCODE_ENV   varchar2(6);
VPAGO_TBRA   number:=0;
vcode_serv  varchar2(6);
VSALIDA     varchar2(1000);
lv_trans_number    number:=0;
cuenta_envio   varchar2(6);
vcodigo_dtl  varchar2(6);
vdescrp     varchar2(60);
vmmonto      number:=0;
CONTADOR      number:=0;
VPAGADA       number:=0;
VPIDM          NUMBER:=0;
V_CAMPUS      VARCHAR2(4);

BEGIN
FOR JUMp IN (  select spriden_id, tbraccd_amount, tbraccd_balance, tbraccd_detail_code, trunc (tbraccd_effective_date) vencimiento, tbraccd_desc, TBRACCD_CROSSREF_NUMBER, TBRACCD_DOCUMENT_NUMBER, TBRACCD_USER
,spriden_pidm as pidm , T.TBRACCD_DATA_ORIGIN , T.TBRACCD_TRAN_NUMBER
  ,TBRACCD_FEED_DATE
  ,TBRACCD_STSP_KEY_SEQUENCE
  ,TBRACCD_PERIOD
  ,TBRACCD_RECEIPT_NUMBER
  ,TBRACCD_TERM_CODE
from tbraccd T
join spriden on spriden_pidm = tbraccd_pidm and spriden_change_ind is null
where tbraccd_detail_code in (
                                             SELECT DISTINCT
                                                    svrrsso_detl_code
                                                    FROM
                                                    svrrsrv A,
                                                    svrrsso,
                                                    svvsrvc
                                                    WHERE 1=1
                                                    AND a.svrrsrv_srvc_code = svrrsso_srvc_code
                                                    AND a.svrrsrv_seq_no = svrrsso_rsrv_seq_no
                                                    AND svvsrvc_code = svrrsso_srvc_code
                                                    AND svrrsrv_inactive_ind = 'Y'
                                                    AND a.svrrsrv_web_ind = 'Y'
                                                    AND a.svrrsrv_srvc_code in (SELECT zstpara_param_id
                                                                                                FROM zstpara
                                                                                                WHERE 1=1
                                                                                                AND zstpara_mapa_id ='AUTOSERVICIOSIU'
                                                                                                and ZSTPARA_PARAM_ID not in ('CAFE','CAPR' )
                                                                                                )
                                                   )
and tbraccd_amount = tbraccd_balance
And tbraccd_balance >0
and trunc (tbraccd_effective_date) BETWEEN TRUNC(SYSDATE)-30 AND TRUNC(SYSDATE)-4
and not exists (  select TBRACCD_TRAN_NUMBER  from tbraccd tt2
                        where tt2.tbraccd_Pidm = T.TBRACCD_PIDM
                          and tt2.TBRACCD_TRAN_NUMBER_PAID = T.TBRACCD_TRAN_NUMBER  )
--and   tbraccd_pidm = 228432
--and rownum < 2
order by 5 desc  ) loop

VPIDM  := jump.PIDM;
   -------PRIMERO VALIDAMOS QUE NO ESTE PAGADO POR QUE SE DA EL CASO QUE AUN PAGADO SE PUEDA CANCELAR---GLOVICX 04/08/2019
           begin
                SELECT 1
                INTO VPAGO_TBRA
                FROM TBRACCD
                WHERE TBRACCD_PIDM = jump.PIDM --FGET_PIDM('010030702')
                AND   TBRACCD_TRAN_NUMBER_PAID = jump.TBRACCD_TRAN_NUMBER
                AND   TBRACCD_DETAIL_CODE   IN ( SELECT TBBDETC_DETAIL_CODE
                                                    FROM TBBDETC
                                                    WHERE 1=1
                                                    AND TBBDETC_TYPE_IND = 'P' );
             exception when others then
                VPAGO_TBRA := 0;

             end;

IF VPAGO_TBRA >= 1 THEN
           VSALIDA:='PAGADO'   ;  ---QUIERE DECIR QUE YA ESTA PAGADO

      --     INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6) VALUES('CANCEL_YA ESTA PAGADO', jump.PIDM, jump.TBRACCD_TRAN_NUMBER, PPCODE, VSALIDA, SYSDATE); COMMIT;
         --- RETURN   VSALIDA;
      --   --dbms_output.put_line('CANCEL_YA ESTA PAGADO:  '||jump.PIDM||'--'|| jump.TBRACCD_TRAN_NUMBER  );
  ELSE
         --------
            BEGIN
                SELECT NVL (MAX (tbraccd_tran_number), 0) + 1
                       INTO lv_trans_number
                       FROM tbraccd
                      WHERE tbraccd_pidm = jump.PIDM;
              EXCEPTION WHEN OTHERS THEN
                   VSALIDA:='Error :'||sqlerrm;
                    lv_trans_number := 0;

             END;
             PPCODE2    := '';
              PCODE_ENV  := '';

         begin
          SELECT distinct SVRRSSO_SRVC_CODE --, SVRRSSO_WSSO_CODE
             into vcode_serv   ----, PCODE_ENV
              FROM SVRRSSO SS
               WHERE 1=1
                 and SVRRSSO_DETL_CODE = jump.TBRACCD_DETAIL_CODE
                 AND ROWNUM <2 ;
          exception when others then
            vcode_serv := jump.TBRACCD_DETAIL_CODE ;
           -- PCODE_ENV  := '';
            end;

          ------------------------calcula el codigo de envio para ver si es internacional------------
         begin
          SELECT DISTINCT SVRSVPR_CAMP_CODE
                  INTO  V_CAMPUS
                FROM SVRSVPR
                   WHERE 1=1
                        AND  SVRSVPR_PIDM   =  jump.PIDM
                        --AND SVRSVPR_SRVS_CODE = 'AC'
                        AND SVRSVPR_PROTOCOL_SEQ_NO = JUMP.TBRACCD_CROSSREF_NUMBER;
              cuenta_envio := cuenta_envio +1;
          exception when others then
           PCODE_ENV :='';
          end;
          -------

          --  INSERT INTO TWPASOW ( VALOR1,VALOR2,VALOR3,VALOR4, VALOR5, valor6, valor7)
         --   VALUES ('P_CAN_SERV_nuevo 1 ', jump.pidm, jump.TBRACCD_TRAN_NUMBER, jump.TBRACCD_DETAIL_CODE,vcode_serv,PCODE_ENV, sysdate); commit;
        --------------------------------------------------------
            begin
                select DISTINCT TBBDETC_DETAIL_CODE code_dtl, tbbdetc_desc descp
                   INTO    vcodigo_dtl, vdescrp
                     FROM TBBDETC T , SZTCCAN ZC
                     where 1=1
                     and  TBBDETC_TYPE_IND   = 'P'
                     and  TBBDETC_DCAT_CODE  = 'CAN'
                  --   and TBBDETC_TAXT_CODE   = 'GN'
                     AND SUBSTR(T.TBBDETC_DETAIL_CODE,3,2)  = SUBSTR(ZC.SZTCCAN_CODE,3,2)
                     AND ZC.SZTCCAN_CODE_SERV  = vcode_serv
                     and   substr(TBBDETC_DETAIL_CODE,1,2)  =  substr(F_GetSpridenID(jump.pidm),1,2);

             --  INSERT INTO TWPASOW ( VALOR1,VALOR2,VALOR3, VALOR4, VALOR5, VALOR6)
              --  VALUES ('SIU_SERV_CODIGO CANCELACION', jump.PIDM,vcode_serv ,vcodigo_dtl,vdescrp, SYSDATE  );

             -- COMMIT;
              vmmonto :=  (jump.TBRACCD_AMOUNT*-1);

           exception when others then
             ----dbms_output.PUT_LINE(' error no se encontro code de detalle ::'||CONTADOR );
                     vcodigo_dtl := '01B4';
           end;


 --------valida tbrappl  PARA VER SI YA ESTA PAGADO O NO EL SERVICIO
        BEGIN

        select COUNT(1)
          INTO  VPAGADA
        from (
            select *    ------SI REGRESA EL VALOR DE MAYOR A UNO YA ESTA PAGADO
            from tbrappl ppl
            where tbrappl_pidm = jump.pidm
              and PPL.TBRAPPL_CHG_TRAN_NUMBER  = jump.TBRACCD_TRAN_NUMBER  ---NO de transaccion del servicio
              and ppl.TBRAPPL_DATA_ORIGIN != 'AD'
              union
            select *    ------SI REGRESA EL VALOR DE MAYOR A UNO YA ESTA PAGADO
            from tbrappl ppl
            where tbrappl_pidm = jump.pidm
              and PPL.TBRAPPL_CHG_TRAN_NUMBER  = jump.TBRACCD_TRAN_NUMBER  ---NO de transaccion del servicio
              and ppl.TBRAPPL_DATA_ORIGIN is  null
              );   ------SOLO AD ES LA UNICA QUE APLICA UN DESCUENTO PERO NO ESTA PAGADA
        exception when others then
          --   --dbms_output.PUT_LINE(' NO ESTA PAGADA  ::'||VPAGADA );
             VPAGADA := 0;
        end;

         begin

               select ZSTPARA_PARAM_VALOR
                  INTO vcode_curr
                from zstpara
                where ZSTPARA_MAPA_ID = 'CAMPUS_AUTOSERV'
                AND ZSTPARA_PARAM_ID = V_CAMPUS; ---ESTE ES EL CAMPUS

        EXCEPTION WHEN OTHERS THEN
           vcode_curr:='Error :'||sqlerrm;
           -- vigencia := 0;
            VSALIDA:='Error en codigo de moneda :'||sqlerrm;
        END;

         ---------------------------------------
   IF VPAGADA = 0 THEN
        --  --dbms_output.PUT_LINE('REGS-INSTR-TBRACCD-'||'-'||Jump.pidm||'-'||Jump.TBRACCD_DETAIL_CODE||'-'|| jump.TBRACCD_TRAN_NUMBER  );
      --    INSERT INTO TWPASOW ( VALOR1,VALOR2,VALOR3, VALOR4, VALOR5, VALOR6)
        --  VALUES ('SIU_SERV_Cancel_CARTERA', jump.PIDM,vcode_serv ,vcodigo_dtl,VPAGADA, SYSDATE  );
         --     COMMIT;
           --------------------------------------------inserta la cancelacion de  tbraccd---
           begin
               INSERT INTO TBRACCD (TBRACCD_PIDM,
                  TBRACCD_TERM_CODE,
                  TBRACCD_DETAIL_CODE,
                  TBRACCD_USER,
                  TBRACCD_ENTRY_DATE,
                  TBRACCD_AMOUNT,
                  TBRACCD_BALANCE,
                  TBRACCD_EFFECTIVE_DATE,
                  TBRACCD_DESC,
                  TBRACCD_CROSSREF_NUMBER,
                  TBRACCD_SRCE_CODE,
                  TBRACCD_ACCT_FEED_IND,
                  TBRACCD_SESSION_NUMBER,
                  TBRACCD_DATA_ORIGIN,
                  TBRACCD_TRAN_NUMBER,
                  TBRACCD_ACTIVITY_DATE,
                  TBRACCD_MERCHANT_ID,
                  TBRACCD_TRANS_DATE,
                  TBRACCD_DOCUMENT_NUMBER
                 ,TBRACCD_FEED_DATE
                 ,TBRACCD_STSP_KEY_SEQUENCE
                 ,TBRACCD_PERIOD
                 ,TBRACCD_CURR_CODE,
                 TBRACCD_TRAN_NUMBER_PAID,
                 TBRACCD_RECEIPT_NUMBER
                    )
              VALUES( jump.PIDM,
                  jump.TBRACCD_TERM_CODE,
                  vcodigo_dtl, --VCODE_DTL,
                   'WWW_JOB2',
                  SYSDATE,
                   jump.TBRACCD_AMOUNT,
                  (jump.TBRACCD_AMOUNT*-1),
                   (SYSDATE),
                  vdescrp,
                  null,  --PNO_SERV,
                  'T',
                  'Y',
                  0,
                  'WEB-BAJA_JOB',
                  lv_trans_number,
                  SYSDATE,
                  NULL,
                  SYSDATE,
                  lv_trans_number
                  ,jump.TBRACCD_FEED_DATE
                  ,jump.TBRACCD_STSP_KEY_SEQUENCE
                  ,jump.TBRACCD_PERIOD
                  ,vcode_curr --'MXN'
                  ,jump.TBRACCD_TRAN_NUMBER
                  ,jump.TBRACCD_RECEIPT_NUMBER
                        );

           -- --dbms_output.PUT_LINE('inserta en tbraccd ::'||jump.pidm||'-'||lv_trans_number||'--'||null||'---'|| sql%rowcount );
            CONTADOR := CONTADOR + sql%rowcount;

            UPDATE TBRACCD
            SET   TBRACCD_DOCUMENT_NUMBER = 'WCANCE'
                  , TBRACCD_TRAN_NUMBER_PAID   = null
            WHERE TBRACCD_PIDM =  jump.PIDM
              AND TBRACCD_TRAN_NUMBER = jump.TBRACCD_TRAN_NUMBER
             -- AND TBRACCD_CROSSREF_NUMBER = jump.seq_no
              ;
            CONTADOR := CONTADOR + sql%rowcount;

            --  INSERT INTO TWPASOW ( VALOR1,VALOR2,VALOR3, VALOR4, VALOR5, VALOR6, valor7)
            -- VALUES ('SIU_tbrac_insert_Cancel_CARTERA', jump.PIDM, lv_trans_number ,vcodigo_dtl, vdescrp,vmmonto, SYSDATE  );

           exception when others then
            -- --dbms_output.PUT_LINE('error al insertar tbraccd code cancelacion::'||sqlerrm );
             null;
           end;


         BEGIN
           UPDATE SVRSVPR v
            SET  SVRSVPR_SRVS_CODE = 'CA',
                 SVRSVPR_USER_ID   =  'WWW_CAN_JOB2',
                 SVRSVPR_ACTIVITY_DATE = SYSDATE
            WHERE 1=1
            AND  V.SVRSVPR_PIDM   = jump.pidm
          --  AND SVRSVPR_SRVS_CODE != 'PA'  --CANELA TODO MENOS LO QUE YA ESTE PAGADO
            AND SVRSVPR_PROTOCOL_SEQ_NO = jump.TBRACCD_CROSSREF_NUMBER;


          ----dbms_output.PUT_LINE('CANCELACION FINAL DEL SERVICIO Y CARTERA:.  '||JUMP.PIDM ||'-'|| jump.TBRACCD_CROSSREF_NUMBER );

         EXCEPTION WHEN OTHERS THEN
             NULL;
             VSALIDA := SQLERRM;
         END;

   end if;

end if;

COMMIT;
end loop;


RETURN('EXITO');


EXCEPTION WHEN OTHERS THEN
----dbms_output.PUT_LINE(' ERROOR EN CANCELA JOB2 '|| SQLERRM);
 -- INSERT INTO TWPASOW ( VALOR1,VALOR2,VALOR3, VALOR4, VALOR5, VALOR6, valor7)
   --          VALUES ('ERROR EN CANCELA JOBS2', VPIDM, vcode_serv ,vcodigo_dtl, lv_trans_number,vmmonto, SYSDATE  );
  --   COMMIT;
RETURN(SQLERRM);

end F_CAN_JOB2;

FUNCTION F_PRECIO_MATERIA_NIVE( ppidm  number, pnivel varchar2, pprograma  varchar2 )
RETURN NUMBER  IS

NPRECIO  NUMBER:= 0;
VCOSTO2   number:= 0;
VCOSTO    number:= 0;
 VDESC       varchar2(30);
 VDESC2     NUMBER:=0;
 vrango1    number;
 vrango2    number;
 VCAMPUS    VARCHAR2(4);
 VPROGRAMA   VARCHAR2(14);
--se le hizo un cambio para que ya no tomara en cuenta el programa que viene del parametro desde SIU, por que los CP cambios de programa
-- no lo conoce SIU y regresa mal los montos.
-- actualizacion glovicx 03/09/2020
-- se agrega una nueva validacion para sacar el precio del parametrizador glovicx 25/06/021 es ta funcion es para los descuentos

BEGIN
       ----------SE OBTIENE EL CAMPUS DEL ALUMNO PARA SABER EL COSTO DEL LA MATERIA  GLOVICX 18/03/2020
       BEGIN
           SELECT distinct (SO.SORLCUR_CAMP_CODE)
            INTO  VCAMPUS
                FROM SORLCUR SO
                where SO.sorlcur_pidm = ppidm --fget_pidm ('240224874')
                AND  SO.SORLCUR_LMOD_CODE = 'LEARNER'
                AND  SO.SORLCUR_LEVL_CODE  = pnivel --'LI'
                AND SO.SORLCUR_TERM_CODE  = ( SELECT MAX(SS.SORLCUR_TERM_CODE)  FROM SORLCUR SS
                                                WHERE 1=1
                                                      AND  SS.sorlcur_pidm = SO.sorlcur_pidm
                                                      AND  SS.SORLCUR_LMOD_CODE = 'LEARNER' );

       EXCEPTION WHEN OTHERS THEN
         VCAMPUS := '';
       END;
            --  AQUI RECALCULA EL PROGRAMA
        BEGIN

                select programa
                   INTO VPROGRAMA
                    from tztprog t
                    where 1=1
                    and pidm = ppidm
                    and  sp = ( select max(sp) from tztprog tt
                                    where 1=1
                                      and t.pidm = tt.pidm
                                        )
                    ;
        EXCEPTION WHEN OTHERS THEN
          VPROGRAMA := pprograma;

        END;





    BEGIN
           SELECT ROUND(nvl(SZTHITA_AVANCE,0))
              INTO VDESC2
                FROM SZTHITA ZT
                WHERE ZT.SZTHITA_PIDM = pPIDM
                AND    ZT.SZTHITA_LEVL  = pnivel
                AND   ZT.SZTHITA_PROG   = VPROGRAMA  ;
              --  --dbms_output.PUT_LINE('SALIDA AVANCE HITA  '|| VDESC2);

       EXCEPTION WHEN OTHERS THEN
        VDESC2 :=0;
                BEGIN
                   SELECT BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 ( pPIDM, VPROGRAMA )
                          INTO VDESC2
                     FROM DUAL;

                    -- --dbms_output.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
                  EXCEPTION WHEN OTHERS THEN
                   VDESC2 :=0;
                  END;
      END;
      -------------------OBTIENE EL COSTO------------
      BEGIN

                   select distinct SZT_PRECIO
                       into VCOSTO2
                        from sztnipr
                        where 1=1
                        and SZT_NIVEL = pnivel
                        and SZT_CAMPUS  =  VCAMPUS
                        and ROUND(VDESC2) between ( SZT_MINIMO ) and (SZT_MAXIMO )
                        and substr(SZT_CODE,1,2) = substr(F_GetSpridenID(pPIDM),1,2);


            EXCEPTION WHEN OTHERS THEN
          VCOSTO2:= 0;
           --dbms_output.PUT_LINE('error en sztnipr ' ||  sqlerrm);
      END;

       --dbms_output.PUT_LINE('SALIDA COSTOS_PARAMETROS2  '|| pPIDM ||'-'|| VDESC2||'-'||pnivel ||'-'|| VCOSTO );
      /*
          IF  vcosto = 0  then

             begin
                  --SE AGREGO LA TABLA SVRRSRV PARA TOMAR DE FORMA NATURAL EL NIVEL PARA TODOS LOS ACCESORIOS GLOVICX 25/05/2021
                SELECT  distinct nvl(MAX (svrrsso_serv_amount), 0)
                 INTO  VCOSTO2
                FROM svrrsso a , tbbdetc tt,SVRRSRV r
                WHERE  1=1
                AND a.SVRRSSO_SRVC_CODE     = R.SVRRSRV_SRVC_CODE
                and a.SVRRSSO_RSRV_SEQ_NO = R.SVRRSRV_SEQ_NO
                and  a.svrrsso_srvc_code = 'NIVE'
                and  a.SVRRSSO_DETL_CODE = tt.TBBDETC_DETAIL_CODE
                AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(PPIDM),1,2)
                 --and  tt.TBBDETC_TAXT_CODE = jump.nivel
                and   r.SVRRSRV_LEVL_CODE = PNIVEL;


              exception when others then
                VCOSTO2 := 0;
              end;


             ELSE
             VCOSTO2 := vcosto;
          end if;
     */
          ------excepcion especial para que los talleres los cobre de 2100 segun el parametrizador-----
--         begin
--           select ZSTPARA_PARAM_VALOR
--             into vparam_mate
--           FROM ZSTPARA
--              WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION'
--               and   ZSTPARA_PARAM_ID  = pMATERIA
--            ;
--
--          exception when others then
--             vparam_mate := VCOSTO2;
--          end;
--
--          if vparam_mate > 0 then
--            VCOSTO2 := vparam_mate;
--            else
--               VCOSTO2 := VCOSTO2 ;
--          end if;

 -- --dbms_output.put_line('el costo final de la materia es|| ' || VCOSTO2 );

if VCOSTO2 > 0 then

RETURN(VCOSTO2);

else
return(0);

end if;


EXCEPTION WHEN OTHERS THEN
VCOSTO2  := 0;
return('ERROR');

END F_PRECIO_MATERIA_NIVE;


function F_envia_mail (ppidm number, pno_serv number,ppcode varchar2, pmonto varchar2 )  return varchar2  IS


VCAMPUS    VARCHAR2(3):='LI';
SUBJECT   VARCHAR2(250):='CONTRATACIÓN DE SERVICIOS SIU';
--MENSAJE   VARCHAR2(1000):='lo que sea es un mensaje cualquiera debe ser html ';
CUENTA    varchar2(14);
--PpIDM      number:= 115957 ;
CCEMAIL     VARCHAR2(100):=  'vsanchro@utel.edu.mx';
EMAIL     VARCHAR2(100);
----SALDO     VARCHAR2(30):='$300.00';
TIPO      NUMBER:=1;
ESTATUS   NUMBER:=1;
vhtml     VARCHAR2 (32767);
vbody     VARCHAR2 (32767);
vhtml2     VARCHAR2 (32767);
vbody2     VARCHAR2 (32767);
VHTMENSJ   VARCHAR2(32767);
nvombre   varchar2(200);
vprograma varchar2(100);
vservicio  varchar2(50);
----PPMONTO   VARCHAR2(10):='$600.00';
pprograma  varchar2(20);
----ppno_serv      number;
-----PPCODE       VARCHAR2(4):= 'NIVE';
vhtmfot     varchar2(500);
vhtmfot2    varchar2(500);
--vno_serv      number;



begin

  BEGIN
        select  replace(SPRIDEN_LAST_NAME,'/',' ' )  ||' '||SPRIDEN_FIRST_NAME, spriden_id
        into nvombre,CUENTA
        from spriden
        where spriden_pidm = PpIDM ;
       EXCEPTION WHEN OTHERS THEN
         nvombre :='';
       END;


       BEGIN
            select DISTINCT sv_svvsrvc.f_get_description (PPCODE) srvc_code_desc
            INTO vservicio
            from dual;
       EXCEPTION WHEN OTHERS THEN
          vprograma :='';
        END;

        begin
            select distinct SVRSVAD_ADDL_DATA_DESC
            into EMAIL
            from svrsvpr v,SVRSVAD VA
            where 1=1
            and  SVRSVPR_SRVC_CODE = PPCODE --'NIVE'
            AND  SVRSVPR_PIDM      = PpIDM
            AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  pno_serv
            and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
            and va.SVRSVAD_ADDL_DATA_DESC  like('%@%')
            ;
         EXCEPTION WHEN OTHERS THEN
          EMAIL :='';

        END;

         begin


            select distinct SVRSVAD_ADDL_DATA_CDE,SVRSVPR_CAMP_CODE
                INTO pprograma , VCAMPUS
            from svrsvpr v,SVRSVAD VA
            where 1=1
            --and  SVRSVPR_SRVC_CODE = 'NIVE'
            AND  SVRSVPR_PIDM   = PpIDM
            AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PNO_SERV
            and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
            --and va.SVRSVAD_ADDL_DATA_DESC  like('%@%')
            and va.SVRSVAD_ADDL_DATA_SEQ in ( 1)
             ; ------el valor 2 es pare el  periodo
         EXCEPTION WHEN OTHERS THEN
          pprograma :='';
          VCAMPUS  := '';

        END;

         BEGIN
           select distinct (SZTDTEC_PROGRAMA_COMP)
               INTO vprograma
                from SZTDTEC
                where 1=1
                and SZTDTEC_PROGRAM =  pprograma;

         EXCEPTION WHEN OTHERS THEN
          vprograma :='';
        END;

vhtml  :=
'<!DOCTYPE html><html lang="es"><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<html>
  <head>
  <h1 >
  <center>
           Registro de Compra de Servicios
  </center>
  </h1>
  </head>';

vbody  := '<html>
 <h3 >
    Estimado(a) Estudiante '||nvombre ||', con matrícula ' ||CUENTA||' inscrito en el programa ' || vprograma||
    '
    Nos complace informarte que la solicitud de servicio número  '||pno_serv||', ' || vservicio ||', ha sido recibida.'||

    '
    Te pedimos estar al pendiente de tu correo ya que a través de este medio nos comunicaremos contigo para proporcionarte más información
     acerca de tu solicitud.';

 vbody := vbody||'
     <html> <center>
          ATENTAMENTE
        UTEL - Universidad Tecnológica Latinoamericana en Línea
        </center></html>';


vhtml2  := 'Registro de Compra de Servicios' ||chr(13);


vbody2  := ' Estimado(a) Estudiante '||nvombre ||', con matrícula ' ||CUENTA||' inscrito en el programa ' || vprograma||chr(13)||chr(13)||
    '
    Nos complace informarte que la solicitud de servicio número  '||pno_serv||', ' || vservicio ||', ha sido recibida.'||chr(13)||chr(13)||

    '
    Te pedimos estar al pendiente de tu correo ya que a través de este medio nos comunicaremos contigo para proporcionarte más información
     acerca de tu solicitud.'||chr(13)||chr(13);


vbody2 := vbody2||'    ATENTAMENTE

                       UTEL - Universidad Tecnológica Latinoamericana en Línea
        '||chr(13)||chr(13);

vhtmfot := '<html>
 <h5 >
 <center><br>
    Su Solicitud será cancelada en 3 diás si no es pagada.
 </center>
 </h5>
</html>';

vhtmfot2 := 'Su Solicitud será cancelada en 3 diás si no es pagada.
 '||chr(13)||chr(13);

--EMAIL :=  '@utel';
if EMAIL  like '%@gmail%' or EMAIL like '%@utel%' or EMAIL like '%@UTEL%' then
VHTMENSJ:= vhtml2||vbody2||vhtmfot2;
else
VHTMENSJ:= vhtml||vbody||vhtmfot;
end if;

------------------manda el mail al alumno------------ esta cerrado de inicio
BANINST1.NOTIFICACION_CANC_SERV.P_ENVIA_CORREO (VCAMPUS,
                             SUBJECT,
                             VHTMENSJ,
                             CUENTA,
                             PpIDM,
                             CCEMAIL, --EMAIL,
                             pmonto,
                             TIPO,
                             ESTATUS) ;
--------------------------manda una copia a los administrativos

FOR NIN  IN (select ZSTPARA_PARAM_VALOR,ZSTPARA_PARAM_ID
                    from zstpara
                    WHERE ZSTPARA_MAPA_ID = 'SIU_MAIL_COPIA'
                    and ZSTPARA_PARAM_ID  = PPCODE )  LOOP
CCEMAIL :=null;
CCEMAIL := nin.ZSTPARA_PARAM_VALOR;

if nin.ZSTPARA_PARAM_ID = PPCODE  then

BANINST1.NOTIFICACION_CANC_SERV.P_ENVIA_CORREO (VCAMPUS,
                             SUBJECT,
                             VHTMENSJ,
                             CUENTA,
                             PpIDM,
                             CCEMAIL, --EMAIL,
                             pmonto,
                             TIPO,
                             ESTATUS) ;


end if;

END LOOP;


----dbms_output.put_line('resultado de salida::  '|| ESTATUS);
 --  insert into twpasow (valor1, valor2, valor3, valor4, valor5, valor6, valor7, valor8, valor15  )
  --  values('envio de emails sericios SIU', ppidm, CUENTA,vprograma,pno_serv, pmonto, ESTATUS , sysdate,substr(VHTMENSJ,1,500)   );

RETURN('EXITO');

EXCEPTION WHEN OTHERS THEN
----dbms_output.PUT_LINE(' ERROOR EN PERIODO VOXY  '|| SQLERRM);
  --insert into twpasow (valor1, valor2, valor3, valor4, valor5, valor6, valor7, valor8, valor15  )
  --  values('ERROORR DE eNvio de emails sericios SIU_ERR', ppidm, CUENTA,vprograma,pno_serv, pmonto, ESTATUS , sysdate, substr(VHTMENSJ,1,500)   );

RETURN(SQLERRM);

end F_envia_mail;

FUNCTION F_DIAS_SEMANA  Return PKG_SERV_SIU.dias_type
IS
 cur_DIAS BANINST1.PKG_SERV_SIU.dias_type;


 begin
        open cur_DIAS for
                    SELECT NUMERO, DIA
                    FROM TSEMANA2
                    order by 1;

       return cur_DIAS;
  Exception
            When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.cur_DIAS: ' || sqlerrm;
           return cur_DIAS;
 end F_DIAS_SEMANA;

FUNCTION F_Datos_solicitud(ppidm  number, pseq_no number  )   Return PKG_SERV_SIU.datos_type
IS
 cur_Datos BANINST1.PKG_SERV_SIU.datos_type;


 begin
        open cur_Datos for
               select  nvl(data.seq,0) seq
                        , nvl(data.pregunta,'No hay información') pregunta
                        ,NVL( case when data.pregunta  = 'Materia' and data.SVRSVPR_SRVS_CODE = 'NIVE' then
                        SUBSTR(data.texto,1, INSTR(data.texto,'-',1)-1)||' -- '||data.codesc
                          when data.pregunta  = 'Materia' and (data.SVRSVPR_SRVS_CODE = 'EXTR' or data.SVRSVPR_SRVS_CODE = 'TISU') then
                           data.texto||' -- '||data.codesc
                        when data.pregunta  = 'Período del curso' then
                        data.texto||'--'||data.codec_parte
                        when upper(data.pregunta)  = upper('Programa Académico') then
                        programa22 ||' -- '|| data.codec_parte
                        when upper(data.pregunta)  = ('F_MESES_COLF') and data.SVRSVPR_CAMP_CODE in ( select DISTINCT ZSTPARA_PARAM_VALOR
                                                                                                          from zstpara
                                                                                                        where 1=1
                                                                                                        and ZSTPARA_MAPA_ID   = 'TITULA_DIFERIDA'
                                                                                                        and ZSTPARA_PARAM_VALOR  = data.SVRSVPR_CAMP_CODE
                                                                                                        AND ZSTPARA_PARAM_ID  =  data.SVRSVPR_SRVS_CODE  )  then
                        upper(data.pregunta)
                        else
                        data.texto
                        END ,'No hay información') C1
                        from (
                        select DISTINCT trim(va.SVRSVAD_ADDL_DATA_DESC)as texto,va.SVRSVAD_ADDL_DATA_SEQ as seq
                        , ra.SVRSRAD_ADDL_DATA_TITLE as pregunta, SUBSTR(SVRSVAD_ADDL_DATA_CDE,1,INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1) codesc
                        , SVRSVAD_ADDL_DATA_CDE codec_parte,ZZ.SZTDTEC_PROGRAMA_COMP programa22,
                          SVRSVPR_SRVS_CODE
                          ,SVRSVPR_CAMP_CODE
                         from svrsvpr v,SVRSVAD VA, SVRSRAD ra,sztdtec zz
                                where 1=1
                                   AND  v.SVRSVPR_PROTOCOL_SEQ_NO = pseq_no
                                   AND  v.SVRSVPR_PIDM            = ppidm
                                   and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                   and  va.SVRSVAD_ADDL_DATA_SEQ  = ra.SVRSRAD_ADDL_DATA_SEQ
                                   and  V.SVRSVPR_SRVC_CODE       = ra.SVRSRAD_SRVC_CODE
                                   and  zz.SZTDTEC_PROGRAM        (+)=  SVRSVAD_ADDL_DATA_CDE
                                   and (SVRSRAD_VIEW_SOURCE       not in ( 'INCREMENTA')
                                        OR SVRSRAD_VIEW_SOURCE  is null)
                               ) data
                             where 1=1
                             order by 1;

       return cur_Datos;
  Exception
            When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.cur_Datos: ' || sqlerrm;
           return cur_Datos;
 end F_Datos_solicitud;


FUNCTION  F_inserta_horario_UNICA ( ppidm number,  pcode varchar2, pperiodo varchar2, pcampus varchar, PSEQ_NO NUMBER )
RETURN VARCHAR2
IS
-----se debe insertar siempre el horario del alumno para la nivelacio. si paga en linea ya esta cagado el horario
-- pero si no paga y se cancela entonces se borra el horario ..
--glovicx 27/06/2019-----
/* Formatted on 27/06/2019 01:55:34 p.m. (QP5 v5.215.12089.38647) */
-----ANONIMO INSERTA HORARIO UNICA---
schd        VARCHAR2(10):= NULL;
title       VARCHAR2(90):= NULL;
credit       NUMBER;  -- VARCHAR2(10):= NULL;
gmod        VARCHAR2(40):=NULL;
f_inicio    VARCHAR2(16):=NULL;
f_fin       VARCHAR2(16):=NULL;
sem         VARCHAR2(10):=NULL;
crn         VARCHAR2(10):= NULL;
pidm_prof   VARCHAR2(14):= '019852882';  -------QUITAR DESPUES DE LAS PRUEBAS
credit_bill  NUMBER  ; --VARCHAR2(10):= NULL;
vl_exite_prof NUMBER:=0;
V_SEQ_NO     NUMBER:=0;
vpparte      VARCHAR2(5);
VMATERIA     VARCHAR2(14);
Vnivel       VARCHAR2(4);
Vgrupo       VARCHAR2(3):='01';
Vsubj        VARCHAR2(5);
Vcrse        VARCHAR2(5);
conta_ptrm   NUMBER:=0;
Vstudy        NUMBER:=0;
VPROGRAMA     VARCHAR2(14);
pidm_prof2    number:=0;
cssrmet      number:=0;
csirasgn     number:=0;
VSALIDA      VARCHAR2(5000):='EXITO';
VNSFRST      NUMBER:=0;
vno_orden     number:=0;
NO_ORDEN_OLD   NUMBER:=0;
VFINI2          VARCHAR2(14);
VFFIN2          VARCHAR2(14);
Vperiodo       VARCHAR2(20);
pregreso      VARCHAR2(1000);
vl_error      VARCHAR2(1000);


--PPIDM      NUMBER;
--PCODE     VARCHAR2(4);
--PPERIODO  VARCHAR2(10);
--pcampus     VARCHAR2(3);
--PSEQ_NO   NUMBER;
begin

--ppidm :=  244815;
--pcode  := 'TISU';
--Pperiodo := '';
--pcampus     := 'UNI';
--PSEQ_NO  := 42812;
--

IF PCODE IN ( 'EXTR', 'TISU') THEN
null;


-----------------------NSERTA TABLA DE PASO PARA PRUEBA S----------------------

 ----dbms_output.put_line('INICIO :1::  '||Ppidm ||'-'|| PSEQ_NO||'-'||PPERIODO ||'-'||PCODE );
    schd := null;
    title := null;
    credit := null;
    gmod :=null;
    f_inicio :=null;
    f_fin :=null;
    sem :=null;
    crn := null;
    pidm_prof := null;
    vl_exite_prof :=0;
    vpparte     := '';

--         INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7)
--         VALUES ('p_INSERTA_HORARIO_UNICA__PARAM_DE INICIO', ppidm ,  pcode , pperiodo , pcampus , PSEQ_NO, SYSDATE  ); COMMIT;
--

                           BEGIN
                          select V.SVRSVPR_PROTOCOL_SEQ_NO
--                                 , case  when INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1) > 0 then
--                                      SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1)
--                                       else
--                                      SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10)-1 )
--                                  end as materia
                                  , SVRSVAD_ADDL_DATA_CDE   MATERIA
                                INTO V_SEQ_NO, vmateria
                             from svrsvpr v,SVRSVAD VA
                                    where SVRSVPR_SRVC_CODE = pcode
                                       AND  SVRSVPR_PIDM   = ppidm
                                        AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PSEQ_NO
                                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                       and va.SVRSVAD_ADDL_DATA_SEQ in ( 2) ; ------el valor 2 es para la materia
                         EXCEPTION WHEN OTHERS THEN
                           VMATERIA :='';
                           V_SEQ_NO := 0;
                           VSALIDA  := SQLERRM;
                         END;

                         -- --dbms_output.put_line('RECUPERA LA MATERIA DE NIVE::'|| vmateria);
                             --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('PASOWWW_SIU_MATERIA ',Ppidm, PSEQ_NO,vmateria, SUBSTR(vl_error,1,100), sysdate);

                          BEGIN
                            select V.SVRSVPR_PROTOCOL_SEQ_NO
                                 , case  when INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1) > 0 then
                                      SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1)
                                       else
                                      SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10)-1 )

                                  end as PPARTE
                                 INTO V_SEQ_NO, vpparte
                               from svrsvpr v,SVRSVAD VA
                                    where SVRSVPR_SRVC_CODE = pcode
                                       AND  SVRSVPR_PIDM   = ppidm
                                        AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PSEQ_NO
                                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                       and va.SVRSVAD_ADDL_DATA_SEQ in (7) ; ------el valor 2 es para la parte de periodo
                         EXCEPTION WHEN OTHERS THEN
                           VPPARTE :='';
                           V_SEQ_NO := 0;
                           VSALIDA  := SQLERRM;
                         END;
                          ----dbms_output.put_line('RECUPERA LA PARTE PERIODO DE NIVE::'|| vpparte);
                          --     INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('PASOWWW_SIU_PPARTEP ',Ppidm, PSEQ_NO,vpparte, SUBSTR(vl_error,1,100),sysdate);

                        BEGIN
                            select V.SVRSVPR_PROTOCOL_SEQ_NO ,
                               SVRSVAD_ADDL_DATA_CDE  PROG
                                 INTO V_SEQ_NO, VPROGRAMA
                               from svrsvpr v,SVRSVAD VA
                                    where SVRSVPR_SRVC_CODE = pcode
                                       AND  SVRSVPR_PIDM   = ppidm
                                       AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PSEQ_NO
                                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                       and va.SVRSVAD_ADDL_DATA_SEQ in ( 1) ; ------el valor1 es programa
                         EXCEPTION WHEN OTHERS THEN
                           VPROGRAMA :='';
                           V_SEQ_NO := 0;
                           VSALIDA  := SQLERRM;
                         END;
                   -------como ya no hay periodo ahora sacamos de la parte del periodo selecionado
                   ------obtenemos el rango de fechas ini y fin
         begin
                select substr(rango,1, instr(rango,'-AL-',1 )-1)as fecha_ini
                        ,substr(rango,instr(rango,'-AL-',1 )+4)as fecha_fin
                        INTO VFINI2, VFFIN2
                from (
                select   --substr(SVRSVAD_ADDL_DATA_DESC,33  )  rango
                      SVRSVAD_ADDL_DATA_DESC  rango
                         from svrsvpr v,SVRSVAD VA
                            where SVRSVPR_SRVC_CODE = pcode
                            AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQ_NO
                              AND  SVRSVPR_PIDM    = ppidm
                               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                               and va.SVRSVAD_ADDL_DATA_SEQ = '7' --- ES EL MISMO DEL PARTE DE PERIODO
                               ) ;

          EXCEPTION WHEN OTHERS  THEN
            VFINI2:= TRUNC(SYSDATE);
            VFFIN2 := TRUNC(SYSDATE)+7;
          END;
         -------CON LA FECHAS BUSCAMOS EL PERIODO Y LO CALCULAMOS
        IF pcode = 'EXTR'  THEN

            Begin

             select SOBPTRM_TERM_CODE
                into Vperiodo
                from sobptrm
                where 1=1
                and  sobptrm_ptrm_code   = TRIM(vpparte)
                AND TRUNC(SOBPTRM_START_DATE)  >=  TO_DATE(TRIM(VFINI2), 'DD/MM/YYYY')
                AND TRUNC(SOBPTRM_END_DATE)    <=  TO_DATE(TRIM(VFFIN2), 'DD/MM/YYYY')
                and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                AND  substr(sobptrm_term_code,5,2) in (81,82,83)
                ;

            Exception
            When Others then
            vl_error :=  sqlerrm;
--            INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 , valor7)
--            VALUES ('INSRT_HORARIO_periodo_ERROORR22:: ',Ppidm, PSEQ_NO,Vperiodo||' *-* '||VPparte, VFINI2, vl_error, VFFIN2);
--            commit;
            VSALIDA  := SQLERRM;
            End;

        ELSIF pcode = 'TISU'  THEN

          Begin

             select SOBPTRM_TERM_CODE
                into Vperiodo
                from sobptrm
                where 1=1
                and  sobptrm_ptrm_code   = TRIM(vpparte)
                AND TRUNC(SOBPTRM_START_DATE)  >=  TO_DATE(TRIM(VFINI2), 'DD/MM/YYYY')
                AND TRUNC(SOBPTRM_END_DATE)    <=  TO_DATE(TRIM(VFFIN2), 'DD/MM/YYYY')
                and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                AND  substr(sobptrm_term_code,5,2) in (84,85,86)
                ;

            Exception
            When Others then
            vl_error :=  sqlerrm;
--            INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 , valor7)
--            VALUES ('INSRT_HORARIO_periodo_ERROORR22:: ',Ppidm, PSEQ_NO,Vperiodo||' *-* '||VPparte, VFINI2, vl_error, VFFIN2);
--            commit;
            VSALIDA  := SQLERRM;
            End;





        END IF;

--         INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 , valor7)
--            VALUES ('INSRT_HORARIO_periodo_ooookkkkk:: ',Ppidm, PSEQ_NO,Vperiodo||' *-* '||VPparte, VFINI2, vl_error, VFFIN2);
--            commit;

                      begin
                       select SCBCRSE_SUBJ_CODE, SCBCRSE_CRSE_NUMB
                         INTO VSUBJ, VCRSE
                        from scbcrse
                         where SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB = vmateria;
                         ----dbms_output.put_line('RECUPERA el SUBJ__CRSE::'|| VSUBJ||'-'||VCRSE);
                     exception when others then
--                       VSUBJ :=null;
  --                     VCRSE :=null;
 -- --dbms_output.put_line('RECUPERA el SUBJ__CRSE:antes:'|| VSUBJ||'-'||VCRSE);
                        if  length(vmateria) = 9  then
                             VSUBJ :=SUBSTR(vmateria,1,4);
                             VCRSE :=SUBSTR(vmateria,5,5);

                       elsif  length(vmateria) = 8  then
                             VSUBJ :=SUBSTR(vmateria,1,4);
                             VCRSE :=SUBSTR(vmateria,5,4);

                            ELSE
                               VSUBJ :=SUBSTR(vmateria,1,3);
                               VCRSE :=SUBSTR(vmateria,4,4);
                       end if;

                      -- VSALIDA  := SQLERRM;
                      -- --dbms_output.put_line('RECUPERA el SUBJ__CRSE222::'|| VSUBJ||'-'||VCRSE);
                     end;

                           Begin
                             select scrschd_schd_code, scbcrse_title, scbcrse_credit_hr_low, SCBCRSE_BILL_HR_LOW
                                into schd, title, credit, credit_bill
                                 from scbcrse, scrschd
                                where scbcrse_subj_code||scbcrse_crse_numb = TRIM(vmateria)
                                 and     scbcrse_eff_term='000000'
                                 and     SCBCRSE_CSTA_CODE  = 'A'
                                 and     scrschd_subj_code=scbcrse_subj_code
                                 and     scrschd_crse_numb=scbcrse_crse_numb
                                 and     scrschd_eff_term=scbcrse_eff_term;
                           Exception
                            When Others then
                                  schd := null;
                                  title := null;
                                  credit := null;
                                  credit_bill :=null;
                                   ----dbms_output.PUT_LINE('EEEERRRROOOR DEL CREDITOS Y MAS :: '|| VSUBJ||'-'||VCRSE);
                                   VSALIDA  := SQLERRM;
                           End;

                      -- --dbms_output.PUT_LINE('SALIDA DEL CREDITOS Y MAS :: '|| schd||'-'|| title||'-'||credit||'-'||credit_bill );
                    --    INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_CREDITOS ',Ppidm, PSEQ_NO,schd||'-'||title, SUBSTR(vl_error,1,100), sysdate);
                            begin
                                select scrgmod_gmod_code
                                      into gmod
                                from scrgmod
                                where scrgmod_subj_code||scrgmod_crse_numb=VMATERIA
                                and     scrgmod_default_ind='D';
                            exception when others then
                                gmod:='1';
                               -- VSALIDA  := SQLERRM;
                            end;
                              ----dbms_output.PUT_LINE('SALIDA D GMOD CODE :: '|| gmod );
                      BEGIN

                       SELECT DISTINCT SMRPRLE_LEVL_CODE
                       INTO VNIVEL
                       FROM SMRPRLE
                       WHERE SMRPRLE_PROGRAM = VPROGRAMA;

                      EXCEPTION WHEN OTHERS THEN
                      VNIVEL :='';
                      VSALIDA  := SQLERRM;
                      END;
                         ----dbms_output.PUT_LINE('SALIDA D NIVEL :: '|| VNIVEL );
                        ---------------------aqui va la validacion de si ya existe el horario entoces hace la compactacion de grupos o no?---
                         begin                  ---- validacion UNO ver si existe el CRN creado para esa materia,parteperiod,periodo en gral
                            SELECT SSBSECT_CRN
                            into CRN
                                FROM SSBSECT
                                WHERE 1=1
                                --and SSBSECT_CRN = 'A9'
                                AND   SSBSECT_TERM_CODE = vPERIODO
                                and   SSBSECT_PTRM_CODE = vpparte
                                and   SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB = vmateria ;

                                null;
                         exception when others then
                         null;
                         crn := null;

                         --VSALIDA  := SQLERRM;
                         end;

                    conta_ptrm :=0;
                   ----dbms_output.put_line('salida 21  '||PPIDM ||'-'|| VPROGRAMA );
                        Begin
                             select count(*)
                                into conta_ptrm
                             from sfbetrm
                             where sfbetrm_term_code=vPERIODO
                             and     sfbetrm_pidm=PPIDM;
                        Exception
                            When Others then
                              conta_ptrm := 0;
                            --  VSALIDA  := SQLERRM;
                        End;


                         if conta_ptrm =0 then
                                Begin
                                        insert into sfbetrm values(vPERIODO, PPIDM, 'EL', sysdate, 99.99, 'Y', null, sysdate, sysdate, null,null,null,null,'WWW_SIU', null,'WWW_SIU', null, 0,null,null, null,null,user,PSEQ_NO);
                                Exception
                                When Others then
                                    VSALIDA  := ('Se presento un error al insertar en la tabla sfbetrm ' || sqlerrm);
                                 -- insert into twpasow(valor1,valor2,valor3,valor4, valor5) values('ERROR_inserta_sfbetrm::1: ',pidm_prof2,PPERIODO,crn, sysdate );commit;
                                End;
                         end if;

                         ------------------------  primer caso el CRN ya existe es decir ya se abrio un grupo para ese periodo, parte de per y materia
                         ---------------hay que utilizar ese grupo para todos los alumnos que pidan nivelacion con las mismas caracteristicas.
                         ----------------solo hay que crear el horario en sfrstrc  con el estatus de la materia RE.
                IF CRN is not null  then
                  ----------------------------ahora valida si esta esta insertado el regs para ese alumno pero tiene estatus dd
                  ----------------------------si es correcto entonces solo cambia el estatus a RE....si, no lo inserta
                            BEGIN
                                  SELECT COUNT(1)
                                    INTO VNSFRST
                                    FROM SFRSTCR  F
                                    WHERE  F.SFRSTCR_CRN     = CRN
                                    AND F.SFRSTCR_TERM_CODE  = vPERIODO
                                    AND F.SFRSTCR_PIDM       = PPIDM
                                    and F.SFRSTCR_PTRM_CODE  = vpparte ;

                             EXCEPTION WHEN OTHERS THEN
                             VNSFRST := 0;
                             END;

                  IF VNSFRST = 0  THEN  ----------como este alumno no a sido  insertado entonces lo hacemos

                               Begin
                                     select distinct max(sorlcur_key_seqno)
                                            into Vstudy
                                      from sorlcur
                                        where sorlcur_pidm        = PPIDM
                                        and     sorlcur_program   = VPROGRAMA
                                        and     sorlcur_lmod_code = 'LEARNER'
                                     --   AND     SORLCUR_CACT_CODE = 'ACTIVE'     ---- se quita filtro por Vic ramirez esto por que los alumnos que estan de baja y quieran una nivelacion no estan activos
                                        and     sorlcur_term_code = (select max(sorlcur_term_code) from sorlcur
                                                                        where   sorlcur_pidm=PPIDM
                                                                        and     sorlcur_program=VPROGRAMA
                                                                        and     sorlcur_lmod_code='LEARNER'
                                                                         --AND     SORLCUR_CACT_CODE = 'ACTIVE'---- se quita filtro por Vic ramirez esto por que los alumnos que estan de baja y quieran una nivelacion no estan activos
                                                                         )
                                        ;
                               Exception
                               when Others then
                                  Vstudy := null;
                                  VSALIDA  := 'Se presento un error al obtener la informacion de SORLCUR-key_seq_no ' ||PPIDM||'-'||  VPERIODO  ||'*'||crn|| sqlerrm;
                               End;

                                                Begin
                                                 -- --dbms_output.put_line('Salida inserta sfrsctcr  21-D :'||PPIDM||'-'||  PPERIODO  ||'*'||crn||'*'|| Vgrupo||'*'||VPparte||'*'||credit_bill||'*'||credit||'*'||gmod||'*'||Pcampus);
                                                 --  INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , valor7) VALUES ('COMPACTA_GRUPOS_INSRT_SFRSTCR--00 ',Ppidm, PSEQ_NO,Pperiodo,crn, sysdate, SUBSTR(VSALIDA,1,500));

                                                    insert into sfrstcr values(
                                                                            VPERIODO,     --SFRSTCR_TERM_CODE
                                                                            Ppidm,     --SFRSTCR_PIDM
                                                                            crn,     --SFRSTCR_CRN
                                                                            1,     --SFRSTCR_CLASS_SORT_KEY
                                                                            Vgrupo,    --SFRSTCR_REG_SEQ
                                                                            VPparte,    --SFRSTCR_PTRM_CODE
                                                                            'RE',     --SFRSTCR_RSTS_CODE
                                                                            sysdate,    --SFRSTCR_RSTS_DATE
                                                                            null,    --SFRSTCR_ERROR_FLAG
                                                                            null,    --SFRSTCR_MESSAGE
                                                                            credit_bill,    --SFRSTCR_BILL_HR
                                                                            3, --SFRSTCR_WAIV_HR
                                                                            credit,     --SFRSTCR_CREDIT_HR
                                                                            credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                                                            credit,     --SFRSTCR_CREDIT_HR_HOLD
                                                                            gmod,     --SFRSTCR_GMOD_CODE
                                                                            null,    --SFRSTCR_GRDE_CODE
                                                                            null,    --SFRSTCR_GRDE_CODE_MID
                                                                            null,    --SFRSTCR_GRDE_DATE
                                                                            'N',    --SFRSTCR_DUPL_OVER
                                                                            'N',    --SFRSTCR_LINK_OVER
                                                                            'N',    --SFRSTCR_CORQ_OVER
                                                                            'N',    --SFRSTCR_PREQ_OVER
                                                                            'N',     --SFRSTCR_TIME_OVER
                                                                            'N',     --SFRSTCR_CAPC_OVER
                                                                            'N',     --SFRSTCR_LEVL_OVER
                                                                            'N',     --SFRSTCR_COLL_OVER
                                                                            'N',     --SFRSTCR_MAJR_OVER
                                                                            'N',     --SFRSTCR_CLAS_OVER
                                                                            'N',     --SFRSTCR_APPR_OVER
                                                                            'N',     --SFRSTCR_APPR_RECEIVED_IND
                                                                            sysdate,      --SFRSTCR_ADD_DATE
                                                                            sysdate,     --SFRSTCR_ACTIVITY_DATE
                                                                            Vnivel,     --SFRSTCR_LEVL_CODE
                                                                            Pcampus,     --SFRSTCR_CAMP_CODE
                                                                            vmateria,     --SFRSTCR_RESERVED_KEY
                                                                            null,     --SFRSTCR_ATTEND_HR
                                                                            'Y',     --SFRSTCR_REPT_OVER
                                                                            'N' ,    --SFRSTCR_RPTH_OVER
                                                                            null,    --SFRSTCR_TEST_OVER
                                                                            'N',    --SFRSTCR_CAMP_OVER
                                                                            'WWW_SIU',    --SFRSTCR_USER
                                                                            'N',    --SFRSTCR_DEGC_OVER
                                                                            'N',    --SFRSTCR_PROG_OVER
                                                                            null,    --SFRSTCR_LAST_ATTEND
                                                                            null,    --SFRSTCR_GCMT_CODE
                                                                            'WWW_SIU',    --SFRSTCR_DATA_ORIGIN
                                                                            sysdate,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                                            'N',  --SFRSTCR_DEPT_OVER
                                                                            'N',  --SFRSTCR_ATTS_OVER
                                                                            'N', --SFRSTCR_CHRT_OVER
                                                                            null, --SFRSTCR_RMSG_CDE
                                                                            null,  --SFRSTCR_WL_PRIORITY
                                                                            null,  --SFRSTCR_WL_PRIORITY_ORIG
                                                                            null,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                                            null, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                                            'N', --SFRSTCR_MEXC_OVER
                                                                            Vstudy,--SFRSTCR_STSP_KEY_SEQUENCE
                                                                            null,--SFRSTCR_BRDH_SEQ_NUM
                                                                            '01',--SFRSTCR_BLCK_CODE
                                                                            null,--SFRSTCR_STRH_SEQNO
                                                                            PSEQ_NO, --SFRSTCR_STRD_SEQNO
                                                                            null,  --SFRSTCR_SURROGATE_ID
                                                                            null, --SFRSTCR_VERSION
                                                                            'WWW_SIU',--SFRSTCR_USER_ID
                                                                            null );--SFRSTCR_VPDI_CODE
                                                 EXCEPTION WHEN OTHERS THEN
                                                   VSALIDA  := 'error ' ||sqlerrm;
                                                   --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , valor7) VALUES ('EERR_COMPACTA_GRUPOS_INSRT_SFRSTCR ',Ppidm, PSEQ_NO,Pperiodo,crn, sysdate, SUBSTR(VSALIDA,1,500));
                                                 end ;

                                         -- --dbms_output.put_line('DESPUES de insert stfrscr ' || PPIDM||'-'||PPERIODO||'-'|| crn|| Vgrupo||'-'||  VPparte||'  EXEX'  );
                                                        -- vl_error  :=  'SI INSERTA SFRSTCR OK ';
                                      --  INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , valor7) VALUES ('YAAAA  COMPACTA_GRUPOS_INSRT_SFRSTCR ',Ppidm, PSEQ_NO,Pperiodo,crn, sysdate, SUBSTR(VSALIDA,1,500));
                                     --  commit;
                                            --------SEGUNDA PARTE ACTUALIZA LOS ASIENTOS O CUPOS POR MATERIA----

                                    Begin
                                         update ssbsect SB
                                                set SB.ssbsect_enrl = SB.ssbsect_enrl + 1
                                          where SB.SSBSECT_TERM_CODE = VPERIODO
                                          And  SB.SSBSECT_CRN  = crn
                                          AND  SB.SSBSECT_PTRM_CODE = VPparte  ;
                                    Exception
                                    When Others then
                                    VSALIDA  := 'Se presento un error al actualizar el enrolamiento ' ||sqlerrm;
                                    End;

                                    Begin
                                            update ssbsect
                                                set ssbsect_seats_avail=ssbsect_seats_avail -1
                                            where SSBSECT_TERM_CODE = VPERIODO
                                             And  SSBSECT_CRN  = crn
                                             AND  SSBSECT_PTRM_CODE = VPparte ;
                                    Exception
                                    When Others then
                                        VSALIDA  := 'Se presento un error al actualizar la disponibilidad del grupo ' ||sqlerrm;
                                    End;

                                    Begin
                                             update ssbsect
                                                    set ssbsect_census_enrl=ssbsect_enrl
                                             Where SSBSECT_TERM_CODE = VPERIODO
                                             And   SSBSECT_CRN  = crn
                                              AND  SSBSECT_PTRM_CODE = VPparte ;
                                    Exception
                                    When Others then
                                        VSALIDA  := 'Se presento un error al actualizar el Censo del grupo ' ||sqlerrm;
                                    End;

                                    --------hace el insert del docente--------------
                                     ---------AQUI BUSCAMOS EL PROFESOR DENTRO DE LA PARAMETRIZACION-------se agrega esta seecion para EXTRA de U.INSURGENTES glovicx 10/05/21
                                        begin

                                            select ZSTPARA_PARAM_VALOR
                                              INTO pidm_prof
                                            from ZSTPARA
                                            where ZSTPARA_MAPA_ID = 'DOCENTE_NIVELAC'
                                            and  ZSTPARA_PARAM_DESC = VMATERIA;

                                        Exception when others then
                                          pidm_prof:=NULL;
                                          VSALIDA  := 'EXITO';

                                        End;

                                              if pidm_prof is null then
                                                   null; --NO HACE NADA--- PERO SIGUE EL FLUJO NO INSERTA EL PROFESOR  PARA CUANDO NO ESTA
                                                   -------CONFIGURADO EL PROFESOR EN EL PARAMETRIZADOR
                                              ELSE
                                                      ----dbms_output.put_line('Crea el CRN para el docente:'|| pidm_prof  ||'*'||crn);

                                                 --------------------convierte el id del profesor en su pidm----
                                                       select FGet_pidm(pidm_prof) into pidm_prof2  from dual;
                                                 ------------------------------------------------------------------

                                                      Begin
                                                            Select count (1)
                                                            Into vl_exite_prof
                                                            from sirasgn
                                                            Where SIRASGN_TERM_CODE = VPERIODO
                                                            And SIRASGN_CRN = crn
                                                            And SIRASGN_PIDM = pidm_prof2;
                                                       Exception
                                                        when others then
                                                          vl_exite_prof := 0;
                                                        --  VSALIDA  := 'Se presento un Error al consultal sirasgn ' ||sqlerrm;
                                                          -- insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6, valor7) values('ERRORRR_profe_mate11  ',ppidm, pidm_prof2,PPERIODO,crn,vl_exite_prof, sysdate );commit;
                                                       End;

                                                        -------------------------
                                                       If vl_exite_prof = 0 then
                                                                Begin
                                                                ----dbms_output.put_line('Salida inserta profe  20-B :'|| PPERIODO  ||'*'||crn||'*'|| pidm_prof||'*'||Vsubj||'*'||Vcrse||'*'||Vgrupo||'*'||schd||'*'||Pcampus);
                                                                --insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6) values('inserta_profe_mate22  ',ppidm , pidm_prof2,PPERIODO,crn, sysdate );commit;

                                                                select count(1)
                                                                  INTO csirasgn
                                                                from sirasgn
                                                                where SIRASGN_TERM_CODE = VPERIODO
                                                                and  SIRASGN_CRN       = crn
                                                                and  SIRASGN_PIDM      = pidm_prof2
                                                                and  SIRASGN_CATEGORY  = '01'
                                                                ;

                                                                if csirasgn > 0 then
                                                                null;
                                                                else
                                                                insert into sirasgn values(VPERIODO, crn, pidm_prof2, '01', 100, null, 100,'Y', null, null,
                                                                                            sysdate, null,null,null,null, 'WWW_SIU', 'WWW_SIU', null, null, null, null,  null,PSEQ_NO);

                                                                end if;
                                                                Exception
                                                                When Others then
                                                                -- VSALIDA  := 'Se presento un Error al consultal sirasgn_count ' ||sqlerrm;
                                                                null;
                                                                End;
                                                       Else
                                                               Begin
                                                                    Update sirasgn
                                                                    set SIRASGN_PRIMARY_IND = null
                                                                     Where SIRASGN_TERM_CODE = VPERIODO
                                                                     And SIRASGN_CRN = crn;
                                                               Exception
                                                                When others then
                                                                -- VSALIDA  := 'Se presento un Error al UPDATE sirasgn ' ||sqlerrm;
                                                                null;
                                                               End;

                                                                Begin
                                                                ----dbms_output.put_line('Salida INST EXEX  20-C :'|| PPERIODO  ||'*'||crn||'*'|| pidm_prof||'*'||Vsubj||'*'||Vcrse||'*'||VGrupo||'*'||schd||'*'||Pcampus);

                                                                --insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6) values('inserta_profe_mate33 ',ppidm, pidm_prof2,PPERIODO,crn, sysdate );commit;

                                                                        insert into sirasgn values(VPERIODO, crn, pidm_prof2, '01', 100, null, 100,'Y', null, null,
                                                                                                             sysdate, null,null,null,null, 'WWW_SIU', 'WWW_SIU', null, null, null, null,  null,PSEQ_NO);
                                                                Exception
                                                                When Others then
                                                                 --VSALIDA  := 'Se presento un Error al INSERTAR sirasgn ' ||sqlerrm;
                                                                null;
                                                                End;

                                                       End if;
                                                end if;





                  ELSE ----SI EXISTE EL MISMO ALUMNO CON L MATERIA Y TODO IGUAL ENTONCES SOLO AJUSTAMOS EL ESTATUS A "RE"

                   UPDATE SFRSTCR  F
                     SET SFRSTCR_RSTS_CODE = 'RE',
                      SFRSTCR_ACTIVITY_DATE = SYSDATE,
                      SFRSTCR_STRD_SEQNO    = PSEQ_NO,
                      F.SFRSTCR_GRDE_CODE   =  null
                    WHERE  F.SFRSTCR_CRN     = CRN
                   AND F.SFRSTCR_TERM_CODE  = VPERIODO
                  AND F.SFRSTCR_PIDM       = PPIDM
                  and F.SFRSTCR_PTRM_CODE  = vpparte ;
                     --  INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('COMPACTA_GRUPOS_UPDATE_SFRSTCR ',Ppidm, PSEQ_NO,Pperiodo,sysdate, SUBSTR(vl_error,1,500));
                     --   commit ;
                      VSALIDA := 'EXITO';
                    ----dbms_output.PUT_LINE('YA EXIESTE EL CRN SOLO LO ACTUALIZO CON CALIFICACION NULLA:: '|| VSALIDA );

                 END IF; -------HASTA AQUI TERMINA EL PRIMER Y SEGUNDO CASO SI YA EXISTE CRN ES LA COMPACTACION DE GRUPOS

            ELSE   -------QUIERE DECIR QUE TODO ES NUEVO E INSERTA TODO DESDE CERO---------
                        --- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_INICIO2 ',Ppidm, PSEQ_NO,VNIVEL, SUBSTR(vl_error,1,100), sysdate);

                    VSALIDA:='EXITO';  --- se reinicia la variable ya que esta entrando en otro proceso y deber ser valor  inicial null

                         begin
                             BEGIN

--
                                    select sztcrnv_crn
                                    into crn
                                    from SZTCRNV
                                    where 1 = 1
                                    and rownum = 1
                                    and sztcrnv_crn not in (select to_number(crn)
                                                            from
                                                            (
                                                            select case when
                                                                substr(SSBSECT_CRN,1,1) in('L','M','A','N') then to_number(substr(SSBSECT_CRN,2,10))
                                                               else
                                                                 to_number(SSBSECT_CRN)
                                                              end crn,
                                                               SSBSECT_CRN
                                                             from ssbsect
                                                              where 1 = 1
                                                              and ssbsect_term_code= Vperiodo
                                                            )
                                            where 1 = 1)
                                    order by 1;

                                EXCEPTION WHEN OTHERS THEN
                                raise_application_error (-20002,'Error al 2 '|| SQLCODE||' Error: '||SQLERRM);
                                ----dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                crn := NULL;
                                VSALIDA  := SQLERRM;
                                END;

                                  ----dbms_output.PUT_LINE('SALIDA De CRN :: '|| CRN );
                               --     INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_CRN ',Ppidm, PSEQ_NO,CRN, SUBSTR(vl_error,1,100),sysdate);
                                if Vnivel ='LI' then
                                crn:='L'||crn;

                                elsif  Vnivel ='MA' then
                                crn:='M'||crn;

                                elsif  Vnivel ='MS' then
                                crn:='A'||crn;

                                elsif  Vnivel ='DO' then
                                crn:='O'||crn;
                                end if;

                              Exception
                                    When Others then
                                    crn := null;
                                    VSALIDA  := SQLERRM;
                          End;

                         --   --dbms_output.PUT_LINE('SALIDA D CRN COMPUESTO :: '|| CRN );
                        --   --dbms_output.PUT_LINE('SALIDA D FECHAS_INI_FIN :: '|| Pperiodo||'-'||VPparte );
                       --     INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('INSRT_HORARIO_FECHAS_antes22',Ppidm, PSEQ_NO,Pperiodo||'-'||VPparte, SUBSTR(vl_error,1,100), sysdate);
                             Begin

                               -- select distinct sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
                               select distinct TO_CHAR(sobptrm_start_date, 'DD/MM/YYYY') , TO_CHAR(sobptrm_end_date, 'DD/MM/YYYY') , sobptrm_weeks
                                into f_inicio, f_fin, sem
                                from sobptrm
                                where sobptrm_term_code  =Vperiodo
                                and     sobptrm_ptrm_code=VPparte
                                and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2);
                             Exception
                             When Others then
                                vl_error := 'No se Encontro fecha ini/ffin para el Periodo= ' ||Vperiodo ||' y Parte de Periodo= '||VPparte ||sqlerrm;
                              --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('INSRT_HORARIO_FECHAS_ERROORR22:: ',Ppidm, PSEQ_NO,Pperiodo||'-'||VPparte, SUBSTR(vl_error,1,200), sysdate);
                              VSALIDA  := SQLERRM;
                             End;
                           --   --dbms_output.PUT_LINE('SALIDA D FECHAS_INI_FIN :: '|| f_inicio||'-'||f_fin );
                            -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_FECHAS22',Ppidm, PSEQ_NO,F_INICIO||'-'||F_FIN, SUBSTR(vl_error,1,200), sysdate);
                        If crn is not null then
                                  Begin

                                  -- --dbms_output.put_line('Salida  20-A :'|| Pperiodo  ||'*'||crn||'*'|| VPparte||'*'||Vgrupo||'*'||schd||'*'||Vsubj||'**'||Vcrse   );
                                    -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_ssbsect22',Ppidm, PSEQ_NO,F_INICIO||'-'||F_FIN, SUBSTR(vl_error,1,100), sysdate);

                                     ------
                                        Insert into ssbsect values (
                                                                            Vperiodo,     --SSBSECT_TERM_CODE
                                                                            crn,     --SSBSECT_CRN
                                                                            VPparte,     --SSBSECT_PTRM_CODE
                                                                            Vsubj,     --SSBSECT_SUBJ_CODE
                                                                            Vcrse,     --SSBSECT_CRSE_NUMB
                                                                            Vgrupo,     --SSBSECT_SEQ_NUMB
                                                                            'A',    --SSBSECT_SSTS_CODE
                                                                             schd,    --SSBSECT_SCHD_CODE
                                                                             Pcampus,    --SSBSECT_CAMP_CODE
                                                                             title,   --SSBSECT_CRSE_TITLE
                                                                             credit,   --SSBSECT_CREDIT_HRS
                                                                             credit_bill,   --SSBSECT_BILL_HRS
                                                                             gmod,   --SSBSECT_GMOD_CODE
                                                                              null,  --SSBSECT_SAPR_CODE
                                                                              null, --SSBSECT_SESS_CODE
                                                                              null,  --SSBSECT_LINK_IDENT
                                                                              null,  --SSBSECT_PRNT_IND
                                                                              'Y',  --SSBSECT_GRADABLE_IND
                                                                               null,  --SSBSECT_TUIW_IND
                                                                               0, --SSBSECT_REG_ONEUP
                                                                               0, --SSBSECT_PRIOR_ENRL
                                                                               0, --SSBSECT_PROJ_ENRL
                                                                               50, --SSBSECT_MAX_ENRL
                                                                                0,--SSBSECT_ENRL
                                                                                50,--SSBSECT_SEATS_AVAIL
                                                                                null,--SSBSECT_TOT_CREDIT_HRS
                                                                                '0',--SSBSECT_CENSUS_ENRL
                                                                                TO_date(f_inicio, 'DD/MM/YYYY'),--SSBSECT_CENSUS_ENRL_DATE
                                                                                sysdate,--SSBSECT_ACTIVITY_DATE
                                                                                TO_date(f_inicio, 'DD/MM/YYYY'),--SSBSECT_PTRM_START_DATE
                                                                                TO_date(f_fin, 'DD/MM/YYYY'),--SSBSECT_PTRM_END_DATE
                                                                                sem,--SSBSECT_PTRM_WEEKS
                                                                                null,--SSBSECT_RESERVED_IND
                                                                                null, --SSBSECT_WAIT_CAPACITY
                                                                                null,--SSBSECT_WAIT_COUNT
                                                                                null,--SSBSECT_WAIT_AVAIL
                                                                                null,--SSBSECT_LEC_HR
                                                                                null,--SSBSECT_LAB_HR
                                                                                null,--SSBSECT_OTH_HR
                                                                                null,--SSBSECT_CONT_HR
                                                                                null,--SSBSECT_ACCT_CODE
                                                                                null,--SSBSECT_ACCL_CODE
                                                                                null,--SSBSECT_CENSUS_2_DATE
                                                                                null,--SSBSECT_ENRL_CUT_OFF_DATE
                                                                                null,--SSBSECT_ACAD_CUT_OFF_DATE
                                                                                null,--SSBSECT_DROP_CUT_OFF_DATE
                                                                                null,--SSBSECT_CENSUS_2_ENRL
                                                                                'Y',--SSBSECT_VOICE_AVAIL
                                                                                'N',--SSBSECT_CAPP_PREREQ_TEST_IND
                                                                                null,--SSBSECT_GSCH_NAME
                                                                                null,--SSBSECT_BEST_OF_COMP
                                                                                null,--SSBSECT_SUBSET_OF_COMP
                                                                                'NOP',--SSBSECT_INSM_CODE
                                                                                null,--SSBSECT_REG_FROM_DATE
                                                                                null,--SSBSECT_REG_TO_DATE
                                                                                null,--SSBSECT_LEARNER_REGSTART_FDATE
                                                                                null,--SSBSECT_LEARNER_REGSTART_TDATE
                                                                                null,--SSBSECT_DUNT_CODE
                                                                                null,--SSBSECT_NUMBER_OF_UNITS
                                                                                0,--SSBSECT_NUMBER_OF_EXTENSIONS
                                                                                'WWW_SIU',--SSBSECT_DATA_ORIGIN
                                                                                'WWW_SIU',--SSBSECT_USER_ID
                                                                                'MOOD',--SSBSECT_INTG_CDE
                                                                                'B',--SSBSECT_PREREQ_CHK_METHOD_CDE
                                                                                user,--SSBSECT_KEYWORD_INDEX_ID
                                                                                null,--SSBSECT_SCORE_OPEN_DATE
                                                                                null,--SSBSECT_SCORE_CUTOFF_DATE
                                                                                null,--SSBSECT_REAS_SCORE_OPEN_DATE
                                                                                null,--SSBSECT_REAS_SCORE_CTOF_DATE
                                                                                null,--SSBSECT_SURROGATE_ID
                                                                                null,--SSBSECT_VERSION
                                                                                PSEQ_NO);--SSBSECT_VPDI_CODE
                                    Exception
                                    When Others then
                                   --  INSERT INTO TWPASOW (VALOR1,VALOR2,VALOR3,VALOR4,VALOR5 ) VALUES ('ERROR_INSRT_HORARIO_SSBSECT22  ',Ppidm, PSEQ_NO,VPparte, SUBSTR(vl_error,1,100));
                                      vl_error := 'Se presento un Error al insertar el nuevo grupo ' ||sqlerrm;
                                      VSALIDA  := SQLERRM;
                                  End;
                            --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('INSERTA_HORARIO_SSBSET22 ',Ppidm, PSEQ_NO,Vsubj||'-'||Vcrse, sysdate, SUBSTR(vl_error,1,500));
                                                   Begin
                                                                update SOBTERM
                                                                     set SOBTERM_CRN_ONEUP = crn
                                                                where SOBTERM_TERM_CODE = Vperiodo;
                                                   Exception
                                                   When Others then
                                                     null;
                                                   End;

                               BEGIN
                                 select count(1)
                                     INTO cssrmet
                                    from  ssrmeet
                                  where SSRMEET_TERM_CODE = Vperiodo
                                  and SSRMEET_CRN = crn;

                                EXCEPTION WHEN OTHERS THEN
                                  VSALIDA  := SQLERRM;
                                  cssrmet := 0;
                                END;

                                            if cssrmet = 1 then
                                                null;
                                             else
                                                   Begin

                                                        insert into ssrmeet values(Vperiodo, crn, null,null,null,null,null,null, sysdate, TO_date(f_inicio, 'DD/MM/YYYY'), TO_date(f_fin, 'DD/MM/YYYY'), '01', null,null,null,null,null,null,null, 'ENL', null, credit, null, 0, null,null,null, 'CLVI', 'WWW_SIU', 'WWW_SIU', null,null,PSEQ_NO);
                                                    Exception
                                                    when Others then
                                                       VSALIDA  := 'Se presento un Error al insertar en ssrmeet ' ||sqlerrm;
                                                   End;
                                             end if;
                                        ---------AQUI BUSCAMOS EL PROFESOR DENTRO DE LA PARAMETRIZACION-------
                                                    begin

                                                        select ZSTPARA_PARAM_VALOR
                                                          INTO pidm_prof
                                                        from ZSTPARA
                                                        where ZSTPARA_MAPA_ID = 'DOCENTE_NIVELAC'
                                                        and  ZSTPARA_PARAM_DESC = VMATERIA;

                                                    Exception when others then
                                                      pidm_prof:=NULL;
                                                      VSALIDA  := 'EXITO';

                                                    End;

                                              if pidm_prof is null then
                                                   null; --NO HACE NADA--- PERO SIGUE EL FLUJO NO INSERTA EL PROFESOR  PARA CUANDO NO ESTA
                                                   -------CONFIGURADO EL PROFESOR EN EL PARAMETRIZADOR
                                              ELSE
                                                      ----dbms_output.put_line('Crea el CRN para el docente:'|| pidm_prof  ||'*'||crn);

                                                 --------------------convierte el id del profesor en su pidm----
                                                       select FGet_pidm(pidm_prof) into pidm_prof2  from dual;
                                                 ------------------------------------------------------------------

                                                      Begin
                                                            Select count (1)
                                                            Into vl_exite_prof
                                                            from sirasgn
                                                            Where SIRASGN_TERM_CODE = VPERIODO
                                                            And SIRASGN_CRN = crn
                                                            And SIRASGN_PIDM = pidm_prof2;
                                                       Exception
                                                        when others then
                                                          vl_exite_prof := 0;
                                                        --  VSALIDA  := 'Se presento un Error al consultal sirasgn ' ||sqlerrm;
                                                          -- insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6, valor7) values('ERRORRR_profe_mate11  ',ppidm, pidm_prof2,PPERIODO,crn,vl_exite_prof, sysdate );commit;
                                                       End;

                                                        -------------------------
                                                       If vl_exite_prof = 0 then
                                                                Begin
                                                                ----dbms_output.put_line('Salida inserta profe  20-B :'|| PPERIODO  ||'*'||crn||'*'|| pidm_prof||'*'||Vsubj||'*'||Vcrse||'*'||Vgrupo||'*'||schd||'*'||Pcampus);
                                                                --insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6) values('inserta_profe_mate22  ',ppidm , pidm_prof2,PPERIODO,crn, sysdate );commit;

                                                                select count(1)
                                                                  INTO csirasgn
                                                                from sirasgn
                                                                where SIRASGN_TERM_CODE = VPERIODO
                                                                and  SIRASGN_CRN       = crn
                                                                and  SIRASGN_PIDM      = pidm_prof2
                                                                and  SIRASGN_CATEGORY  = '01'
                                                                ;

                                                                if csirasgn > 0 then
                                                                null;
                                                                else
                                                                insert into sirasgn values(VPERIODO, crn, pidm_prof2, '01', 100, null, 100,'Y', null, null,
                                                                                            sysdate, null,null,null,null, 'WWW_SIU', 'WWW_SIU', null, null, null, null,  null,PSEQ_NO);

                                                                end if;
                                                                Exception
                                                                When Others then
                                                                -- VSALIDA  := 'Se presento un Error al consultal sirasgn_count ' ||sqlerrm;
                                                                null;
                                                                End;
                                                       Else
                                                               Begin
                                                                    Update sirasgn
                                                                    set SIRASGN_PRIMARY_IND = null
                                                                     Where SIRASGN_TERM_CODE = VPERIODO
                                                                     And SIRASGN_CRN = crn;
                                                               Exception
                                                                When others then
                                                                -- VSALIDA  := 'Se presento un Error al UPDATE sirasgn ' ||sqlerrm;
                                                                null;
                                                               End;

                                                                Begin
                                                                ----dbms_output.put_line('Salida INST EXEX  20-C :'|| PPERIODO  ||'*'||crn||'*'|| pidm_prof||'*'||Vsubj||'*'||Vcrse||'*'||VGrupo||'*'||schd||'*'||Pcampus);

                                                                --insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6) values('inserta_profe_mate33 ',ppidm, pidm_prof2,PPERIODO,crn, sysdate );commit;

                                                                        insert into sirasgn values(VPERIODO, crn, pidm_prof2, '01', 100, null, 100,'Y', null, null,
                                                                                                             sysdate, null,null,null,null, 'WWW_SIU', 'WWW_SIU', null, null, null, null,  null,PSEQ_NO);
                                                                Exception
                                                                When Others then
                                                                 --VSALIDA  := 'Se presento un Error al INSERTAR sirasgn ' ||sqlerrm;
                                                                null;
                                                                End;

                                                       End if;
                                                end if;


                                                conta_ptrm :=0;
                                               ----dbms_output.put_line('salida 21  '||PPIDM ||'-'|| VPROGRAMA );
                                                    Begin
                                                         select count(*)
                                                            into conta_ptrm
                                                         from sfbetrm
                                                         where sfbetrm_term_code=VPERIODO
                                                         and     sfbetrm_pidm=PPIDM;
                                                    Exception
                                                        When Others then
                                                          conta_ptrm := 0;
                                                           VSALIDA  := 'Se presento un Error al conunt sfbetrm ' ||sqlerrm;
                                                    End;


                                                     if conta_ptrm =0 then
                                                            Begin
                                                                    insert into sfbetrm values(VPERIODO, PPIDM, 'EL', sysdate, 99.99, 'Y', null, sysdate, sysdate, null,null,null,null,'WWW_SIU', null,'WWW_SIU', null, 0,null,null, null,null,user,PSEQ_NO);
                                                            Exception
                                                            When Others then
                                                                VSALIDA  := ('Se presento un error al insertar en la tabla sfbetrm ' || sqlerrm);
                                                               --insert into twpasow(valor1,valor2,valor3,valor4, valor5) values('ERROR_inserta_sfbetrm22 ',pidm_prof2,PPERIODO,crn, sysdate );commit;
                                                            End;
                                                     end if;

                                             Begin
                                                     select distinct max(sorlcur_key_seqno)
                                                            into Vstudy
                                                      from sorlcur
                                                        where sorlcur_pidm        = PPIDM
                                                        and     sorlcur_program   = VPROGRAMA
                                                        and     sorlcur_lmod_code = 'LEARNER'
                                                      --  AND     SORLCUR_CACT_CODE = 'ACTIVE'
                                                        and     sorlcur_term_code = (select max(sorlcur_term_code) from sorlcur
                                                                                        where   sorlcur_pidm=PPIDM
                                                                                        and     sorlcur_program=VPROGRAMA
                                                                                        and     sorlcur_lmod_code='LEARNER'
                                                                                         --AND     SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                         )
                                                        ;
                                               Exception
                                               when Others then
                                                  Vstudy := 1;
                                                  VSALIDA  := 'Se presento un error al obtener la informacion de SORLCUR-key_seq_no ' ||PPIDM||'-'||  VPERIODO  ||'*'||crn|| sqlerrm;
                                               End;

                                        BEGIN

                                            SELECT COUNT(1)
                                            INTO VNSFRST
                                            FROM SFRSTCR  F
                                            WHERE  F.SFRSTCR_CRN     = crn
                                            AND F.SFRSTCR_TERM_CODE  =  VPERIODO
                                            AND F.SFRSTCR_PIDM       = PPIDM;

                                         EXCEPTION WHEN OTHERS THEN
                                         VNSFRST := 0;
                                          VSALIDA  := 'Se presento un Error al count sfrstrc  ' ||sqlerrm;
                                         END;
                                --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , VALOR7, VALOR8 ) VALUES ('PASOWW_SIU_INSERT_SFRSTCR_ANTES ',Ppidm, PPERIODO,crn||'-'||VPparte,sysdate,  Vstudy , VNSFRST, VSALIDA);
                               -- COMMIT;
                                IF VNSFRST = 0  THEN
                                                   Begin
                                                 --  --dbms_output.put_line('Salida inserta sfrsctcr  21-D :'||PPIDM||'-'||  PPERIODO  ||'*'||crn||'*'|| Vgrupo||'*'||VPparte||'*'||credit_bill||'*'||credit||'*'||gmod||'*'||Pcampus);


                                                    insert into sfrstcr values(
                                                                                        VPERIODO,     --SFRSTCR_TERM_CODE
                                                                                        Ppidm,     --SFRSTCR_PIDM
                                                                                        crn,     --SFRSTCR_CRN
                                                                                        1,     --SFRSTCR_CLASS_SORT_KEY
                                                                                        Vgrupo,    --SFRSTCR_REG_SEQ
                                                                                        VPparte,    --SFRSTCR_PTRM_CODE
                                                                                        'RE',     --SFRSTCR_RSTS_CODE
                                                                                        sysdate,    --SFRSTCR_RSTS_DATE
                                                                                        null,    --SFRSTCR_ERROR_FLAG
                                                                                        null,    --SFRSTCR_MESSAGE
                                                                                        credit_bill,    --SFRSTCR_BILL_HR
                                                                                        3, --SFRSTCR_WAIV_HR
                                                                                        credit,     --SFRSTCR_CREDIT_HR
                                                                                        credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                                                                        credit,     --SFRSTCR_CREDIT_HR_HOLD
                                                                                        gmod,     --SFRSTCR_GMOD_CODE
                                                                                        null,    --SFRSTCR_GRDE_CODE
                                                                                        null,    --SFRSTCR_GRDE_CODE_MID
                                                                                        null,    --SFRSTCR_GRDE_DATE
                                                                                        'N',    --SFRSTCR_DUPL_OVER
                                                                                        'N',    --SFRSTCR_LINK_OVER
                                                                                        'N',    --SFRSTCR_CORQ_OVER
                                                                                        'N',    --SFRSTCR_PREQ_OVER
                                                                                        'N',     --SFRSTCR_TIME_OVER
                                                                                        'N',     --SFRSTCR_CAPC_OVER
                                                                                        'N',     --SFRSTCR_LEVL_OVER
                                                                                        'N',     --SFRSTCR_COLL_OVER
                                                                                        'N',     --SFRSTCR_MAJR_OVER
                                                                                        'N',     --SFRSTCR_CLAS_OVER
                                                                                        'N',     --SFRSTCR_APPR_OVER
                                                                                        'N',     --SFRSTCR_APPR_RECEIVED_IND
                                                                                        sysdate,      --SFRSTCR_ADD_DATE
                                                                                        sysdate,     --SFRSTCR_ACTIVITY_DATE
                                                                                        Vnivel,     --SFRSTCR_LEVL_CODE
                                                                                        Pcampus,     --SFRSTCR_CAMP_CODE
                                                                                        vmateria,     --SFRSTCR_RESERVED_KEY
                                                                                        null,     --SFRSTCR_ATTEND_HR
                                                                                        'Y',     --SFRSTCR_REPT_OVER
                                                                                        'N' ,    --SFRSTCR_RPTH_OVER
                                                                                        null,    --SFRSTCR_TEST_OVER
                                                                                        'N',    --SFRSTCR_CAMP_OVER
                                                                                        'WWW_SIU',    --SFRSTCR_USER
                                                                                        'N',    --SFRSTCR_DEGC_OVER
                                                                                        'N',    --SFRSTCR_PROG_OVER
                                                                                        null,    --SFRSTCR_LAST_ATTEND
                                                                                        null,    --SFRSTCR_GCMT_CODE
                                                                                        'WWW_SIU',    --SFRSTCR_DATA_ORIGIN
                                                                                        sysdate,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                                                        'N',  --SFRSTCR_DEPT_OVER
                                                                                        'N',  --SFRSTCR_ATTS_OVER
                                                                                        'N', --SFRSTCR_CHRT_OVER
                                                                                        null, --SFRSTCR_RMSG_CDE
                                                                                        null,  --SFRSTCR_WL_PRIORITY
                                                                                        null,  --SFRSTCR_WL_PRIORITY_ORIG
                                                                                        null,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                                                        null, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                                                        'N', --SFRSTCR_MEXC_OVER
                                                                                        Vstudy,--SFRSTCR_STSP_KEY_SEQUENCE
                                                                                        null,--SFRSTCR_BRDH_SEQ_NUM
                                                                                        '01',--SFRSTCR_BLCK_CODE
                                                                                        null,--SFRSTCR_STRH_SEQNO
                                                                                        PSEQ_NO, --SFRSTCR_STRD_SEQNO
                                                                                        null,  --SFRSTCR_SURROGATE_ID
                                                                                        null, --SFRSTCR_VERSION
                                                                                        'WWW_SIU',--SFRSTCR_USER_ID
                                                                                        null );--SFRSTCR_VPDI_CODE

                                                         ----dbms_output.put_line('DESPUES de insert stfrscr ' || PPIDM||'-'||PPERIODO||'-'|| crn|| Vgrupo||'-'||  VPparte||'NIVE'  );
                                                        -- vl_error  :=  'SI INSERTA SFRSTCR OK ';
                                                        --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('INSRT_SFRSTCR_SEGUNDO22 ',Ppidm, PSEQ_NO,Pperiodo,sysdate, SUBSTR(vl_error,1,500));

                                                                Begin
                                                                     update ssbsect
                                                                            set ssbsect_enrl = ssbsect_enrl + 1
                                                                      where SSBSECT_TERM_CODE = VPERIODO
                                                                      And SSBSECT_CRN  = crn;
                                                                Exception
                                                                When Others then
                                                                VSALIDA  := 'Se presento un error al actualizar el enrolamiento ' ||sqlerrm;
                                                                End;

                                                                Begin
                                                                        update ssbsect
                                                                            set ssbsect_seats_avail=ssbsect_seats_avail -1
                                                                        where SSBSECT_TERM_CODE = VPERIODO
                                                                         And SSBSECT_CRN  = crn;
                                                                Exception
                                                                When Others then
                                                                    VSALIDA  := 'Se presento un error al actualizar la disponibilidad del grupo ' ||sqlerrm;
                                                                End;

                                                                Begin
                                                                         update ssbsect
                                                                                set ssbsect_census_enrl=ssbsect_enrl
                                                                         Where SSBSECT_TERM_CODE = VPERIODO
                                                                         And SSBSECT_CRN  = crn;
                                                                Exception
                                                                When Others then
                                                                    VSALIDA  := 'Se presento un error al actualizar el Censo del grupo ' ||sqlerrm;
                                                                End;

                                                                Begin
                                                                    Update sgbstdn a
                                                                    set a.SGBSTDN_STYP_CODE ='C',
                                                                        A.SGBSTDN_USER_ID  = 'WWW_SIU'
                                                                    Where a.SGBSTDN_PIDM = Ppidm
                                                                    And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                                                                           from sgbstdn a1
                                                                                                                           Where a1.SGBSTDN_PIDM = a.SGBSTDN_PIDM
                                                                                                                           And a1.SGBSTDN_PROGRAM_1 = a.SGBSTDN_PROGRAM_1)
                                                                     And a.SGBSTDN_PROGRAM_1 = VPROGRAMA;
                                                                Exception
                                                                    When Others then
                                                                    VSALIDA  := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||sqlerrm;
                                                                End;



                                                                conta_ptrm:=0;

                                                                Begin
                                                                    Select count (*)
                                                                        Into conta_ptrm
                                                                    from sfrareg
                                                                    where SFRAREG_PIDM = Ppidm
                                                                    And SFRAREG_TERM_CODE = VPERIODO
                                                                    And SFRAREG_CRN = crn
                                                                    And SFRAREG_EXTENSION_NUMBER = 0
                                                                    And SFRAREG_RSTS_CODE = 'RE';
                                                                Exception
                                                                When Others then
                                                                   conta_ptrm :=0;
                                                                    VSALIDA  := 'Se presento un Error al count sfrareg ' ||sqlerrm;
                                                                End;

                                                                If conta_ptrm = 0 then

                                                                     Begin
                                                                       ----dbms_output.put_line(' SALIDA 22A--antes de insertar sfrareg  ' || Ppidm||'-'||PPERIODO||'-'|| crn||f_inicio||'-'|| f_fin||'-'|| 'N'||'-'||'N'   );
                                                                        if  f_inicio is not null  then
                                                                             insert into sfrareg values(PPIDM, VPERIODO, crn , 0, 'RE', TO_date(f_inicio, 'DD/MM/YYYY'), TO_date(f_fin, 'DD/MM/YYYY'), 'N','N', sysdate, 'WWW_SIU', null,null,null,null,null,null,null,null, 'WWW_SIU', sysdate, null,null,PSEQ_NO);
                                                                        end if;

                                                                     Exception
                                                                       When Others then
                                                                          VSALIDA  := 'error al insertar el registro de la materia para sfrareg  ' ||sqlerrm;
                                                                     End;
                                                                End if;
                                                      -- commit;
                                                    Exception
                                                   when Others then
                                                    ----INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4, valor6 )  VALUES ('PASOWWW_SIU_GRal',Ppidm, PSEQ_NO,sysdate,  SUBSTR(vl_error,1,100));
                                                       VSALIDA  := 'Se presento un error al insertar al alumno en el grupo3  ' ||sqlerrm;
                                                End;
                                  END IF;
                                    -- commit;
                                                  ----dbms_output.put_line('se termina proceso gral ' ||VSALIDA);
                         else
                            VSALIDA  := 'No inserto Horario: ' ||sqlerrm;
                        --  INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_FINALIZA ',Ppidm, PSEQ_NO,Pperiodo, SUBSTR(vl_error,1,100), sysdate);
                        End if;
             END IF; -----ES EL FIN FINAL DE LA COMPACTACION DE GRUPO

    IF VSALIDA = 'EXITO' then
    null;

       ---------------------------aqui va el update con el numero de recibo nuevo glovicx 26/11/2019

       begin  -------------AQUI BUSCA EL NUMERO DE ORDEN ACTUAL EL MAS RECIENTE
        select MAX(TBRACCD_RECEIPT_NUMBER)
        into vno_orden
            from tbraccd t
            where tbraccd_pidm =  ppidm
          --  and TBRACCD_DESC like ('%NIVELA%')
           -- and t.TBRACCD_DOCUMENT_NUMBER = vmateria
           -- and t.TBRACCD_USER       =  'WWW_SIU'
           AND TBRACCD_CROSSREF_NUMBER = PSEQ_NO
           ;
     exception when others then

     vno_orden := 0;
     end;

         BEGIN
                       -------BUSCA SI EL CRN YA EXISTIA Y TENIA UN NUMERO DE ORDEN POR LA COMPACTACION DE GRUPO
                       ------- SI YA EXISTE ENTONCES TENGO QUE RECUPERAR ESA ORDEN Y ACTUALIZARLA EN LA CARTERA CANCELADA
                       -----  ESTA REGLA SE ACORDO CON VICTOR RAMIREZ 04/12/2019-----
            SELECT SFRSTCR_VPDI_CODE
            INTO NO_ORDEN_OLD
            FROM SFRSTCR
            where 1= 1
            and SFRSTCR_PIDM = ppidm
            and SFRSTCR_CRN  = CRN
            And substr (SFRSTCR_TERM_CODE, 5,1) = '8'
            And SFRSTCR_RSTS_CODE = 'RE'
            ;

         EXCEPTION WHEN OTHERS THEN
           NO_ORDEN_OLD := 0;
         END;

       IF NO_ORDEN_OLD > 0 THEN-----SI HAY NUMERO DE ORDEN VIEJO LO ACTUALIZA EN LA CARTERA VIEJA POR EL NUEVO NUM ORDEN

          UPDATE  tbraccd t
            SET TBRACCD_RECEIPT_NUMBER = vno_orden --NO_ORDEN_NUEVO
            where tbraccd_pidm =  ppidm
           -- and TBRACCD_DESC like ('%NIVELA%')
            --and t.TBRACCD_DOCUMENT_NUMBER like (:vmateria
            AND TBRACCD_RECEIPT_NUMBER = NO_ORDEN_OLD  --NO_ORden anterior
            ;
       END IF;

     if vno_orden > 0 then
       ----dbms_output.put_line('salida no_orden '||vno_orden );
       begin

          update  SFRSTCR
             set SFRSTCR_VPDI_CODE  = vno_orden,
               SFRSTCR_ADD_DATE     = sysdate
              where 1= 1
               and SFRSTCR_PIDM = ppidm
               and SFRSTCR_CRN  = CRN
               And substr (SFRSTCR_TERM_CODE, 5,1) = '8'
               And SFRSTCR_RSTS_CODE = 'RE';

        --  --dbms_output.put_line('Actualiza::  '||vno_orden||'-'|| jump.pidm ||'--'||jump.CRN ||'--'||jump.materia );
       exception when others then
       null;
        ----dbms_output.put_line('error en UPDATE :  ' ||sqlerrm  );
        end;


     end if;
             COMMIT;
             RETURN ('EXITO');

     ---------------------------------------------------------------------------------fin
     --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWW_SIU_FINALIZA_HORARIO ',Ppidm, PSEQ_NO,sysdate,  pregreso,SUBSTR(vl_error,1,90));

     ----dbms_output.put_line('se termina proceso gral  EXITO-->>1 ' ||pregreso);
    else
    pregreso := sqlerrm;
      ----dbms_output.put_line('se termina proceso gral--3 ' ||VSALIDA);

      ROLLBACK;
       RETURN( pregreso);
    end if;

 null;
--commit;
END IF;

exception when others then
----dbms_output.put_line('ERRORR:  termina proceso gral ' ||VSALIDA);
ROLLBACK;
      RETURN( pregreso);

end F_inserta_horario_UNICA;


FUNCTION F_MATERIA_NIVE_UNI (PPIDM NUMBER, pprogram varchar2 ) Return VARCHAR2  IS

  CONTADOR   NUMBER;
 VSALIDA    varchar2(300);
 VDESC       varchar2(30);
 VDESC2     NUMBER:=0;
 VCOSTO     NUMBER;
 VCOSTO2    NUMBER;
 vrango1    number;
 vrango2    number;
 vparam_mate    NUMBER;
 VTALLERES    NUMBER:=0;
 vcampus      varchar2(4);
 VFUNCION     varchar2(40);
 PACAMPUS     VARCHAR2(4);
 TERMATERIAS  VARCHAR2(10);

BEGIN

         DELETE FROM extraor2
         WHERE  PIDM = PPIDM ;

-- nuevo aqui buscamos el nuevo valor del periodo en shgrade glovicx 17/01/022

      begin
         select distinct ZSTPARA_PARAM_DESC
           INTO TERMATERIAS
        from ZSTPARA
        where 1=1
        and ZSTPARA_MAPA_ID = 'ESC_SHAGRD'
        and ZSTPARA_PARAM_ID = substr(F_GetSpridenID(PPIDM),1,2);
      exception when others then
          TERMATERIAS := null;

       end;


----------------------aqui determinamos si el campus es unica o es utel glovicx 23/11/2020
FOR JUMP IN (
        select distinct datos.materia MATERIA, --||'|'||costo,
        --rpad(cc.SCRSYLN_LONG_COURSE_TITLE,40,'-') NOMBRE_MATERIA, --||' $ '|| costo,
        cc.SCRSYLN_LONG_COURSE_TITLE  NOMBRE_MATERIA,
        datos.programa AS PROGRAMA,
        -- nvl(datos.costo, 000)as costo,
        DATOS.PIDM AS PIDM
        ,datos.nivel as nivel
        ,datos.sp
        ,DATOS.CAMPUS
        from (
                SELECT (qq.ssbsect_subj_code || qq.ssbsect_crse_numb) materia
                --( select M.SZTMACO_MATPADRE from sztmaco m where M.SZTMACO_MATHIJO = qq.SSBSECT_SUBJ_CODE || qq.SSBSECT_CRSE_NUMB) materia,
                , CASE
                WHEN qq.ssbsect_seq_numb IS NULL
                THEN
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                ELSE
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                END nombre_materia,
                so.SORLCUR_PROGRAM as programa
                ,SO.SORLCUR_PIDM as pidm
                ,SO.SORLCUR_LEVL_CODE AS NIVEL
                ,'1' FINAL
                ,cr.SFRSTCR_STSP_KEY_SEQUENCE as Sp
                ,SO.SORLCUR_CAMP_CODE  AS CAMPUS
                FROM ssbsect qq, sfrstcr cr, shrgrde sh, sorlcur so, stvterm x, spriden sp
                ,(SELECT ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_ID, ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION' ) cos
                WHERE 1=1
                AND cr.sfrstcr_pidm = PPIDM
                AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                AND cr.sfrstcr_crn = qq.ssbsect_crn
                AND sh.shrgrde_code = cr.SFRSTCR_GRDE_CODE
                and sh.SHRGRDE_LEVL_CODE = cr.SFRSTCR_LEVL_CODE
                AND sh.shrgrde_passed_ind = 'N'
                and cr.SFRSTCR_GRDE_CODE is not null
                AND so.SORLCUR_LMOD_CODE = 'LEARNER'
                AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS')
                AND sh.shrgrde_levl_code = so.SORLCUR_LEVL_CODE
                AND cr.sfrstcr_pidm = so.sorlcur_pidm
                And so.sorlcur_program = pprogram
                And cr.SFRSTCR_STSP_KEY_SEQUENCE = so.SORLCUR_KEY_SEQNO
                AND so.sorlcur_term_code = x.stvterm_code
                AND sp.spriden_change_ind IS NULL
                and cr.sfrstcr_pidm = SP.SPRIDEN_PIDM
                and cos.ZSTPARA_PARAM_DESC(+) = qq.ssbsect_subj_code || qq.ssbsect_crse_numb
             /*   AND SO.SORLCUR_TERM_CODE  = (SELECT MAX (S2.SORLCUR_TERM_CODE  )  FROM SORLCUR S2
                                                 WHERE 1=1
                                                   AND  S2.SORLCUR_PROGRAM  = SO.SORLCUR_PROGRAM
                                                   AND  S2.SORLCUR_PIDM     =   SO.SORLCUR_PIDM   )  */

                minus
                SELECT qq.ssbsect_subj_code || qq.ssbsect_crse_numb materia
                , CASE
                WHEN qq.ssbsect_seq_numb IS NULL
                THEN
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                ELSE
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                END nombre_materia,
                so.SORLCUR_PROGRAM as programa
                ,SO.SORLCUR_PIDM as pidm
                ,SO.SORLCUR_LEVL_CODE AS NIVEL
                ,'2' FINAL
                ,cr.SFRSTCR_STSP_KEY_SEQUENCE as Sp
                  ,SO.SORLCUR_CAMP_CODE  AS CAMPUS
                FROM ssbsect qq, sfrstcr cr, sorlcur so, stvterm x, spriden sp
                ,(SELECT ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_ID, ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION' ) cos
                WHERE 1=1
                AND cr.sfrstcr_pidm = PPIDM --fget_pidm('010075696')
                AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                AND cr.sfrstcr_crn = qq.ssbsect_crn
                and cr.SFRSTCR_GRDE_CODE is null
                and cr.SFRSTCR_RSTS_CODE in ('RE', 'DD')
                AND so.SORLCUR_LMOD_CODE = 'LEARNER'
                AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS')
                AND cr.sfrstcr_pidm = so.sorlcur_pidm
                And so.sorlcur_program = pprogram
                AND so.sorlcur_term_code = x.stvterm_code
                AND sp.spriden_change_ind IS NULL
                and cr.sfrstcr_pidm = SP.SPRIDEN_PIDM
                And cr.SFRSTCR_STSP_KEY_SEQUENCE = so.SORLCUR_KEY_SEQNO
                and cos.ZSTPARA_PARAM_DESC(+) = qq.ssbsect_subj_code || qq.ssbsect_crse_numb
              /*   AND SO.SORLCUR_TERM_CODE  = (SELECT MAX (S2.SORLCUR_TERM_CODE  )  FROM SORLCUR S2
                                                 WHERE 1=1
                                                   AND  S2.SORLCUR_PROGRAM  = SO.SORLCUR_PROGRAM
                                                   AND  S2.SORLCUR_PIDM     =   SO.SORLCUR_PIDM   ) */

                ) datos
               , SCRSYLN cc
                where 1=1
                and SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB = datos.materia
                and datos.materia   in (SELECT ZSTPARA_PARAM_VALOR   FROM ZSTPARA  WHERE 1=1
                                            AND ZSTPARA_MAPA_ID = ('EXTRA_UNICA') )
                --AND SCBCRSE_CSTA_CODE = 'A'
                AND NOT EXISTS
                (SELECT 1
                FROM SVRSVPR p, SVRSVAD h
                WHERE p.SVRSVPR_SRVC_CODE in  ('EXTR' ,'TISU')
                AND P.SVRSVPR_PIDM = PPIDM --fget_pidm('010075696')
                AND p.SVRSVPR_SRVS_CODE in ('AC','PA')
                AND h.SVRSVAD_PROTOCOL_SEQ_NO = p.SVRSVPR_PROTOCOL_SEQ_NO
                AND SVRSVAD_ADDL_DATA_CDE =  datos.materia )
                and datos.materia NOT in ( select SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB
                FROM ssbsect qq, sfrstcr cr, shrgrde SH
                WHERE 1=1
                AND cr.sfrstcr_pidm = PPIDM --fget_pidm('010075696')
                AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                AND cr.sfrstcr_crn = qq.ssbsect_crn
                and  SHRGRDE_TERM_CODE_EFFECTIVE   = TERMATERIAS
                and ( cr.SFRSTCR_GRDE_CODE in ('6.0','7.0','8.0','9.0','10.0')
                or cr.SFRSTCR_GRDE_CODE is null )
                AND CR.SFRSTCR_GRDE_CODE = SH.SHRGRDE_CODE
                AND CR.SFRSTCR_LEVL_CODE = SH.SHRGRDE_LEVL_CODE
                AND shrgrde_passed_ind = 'Y' ---------ESTO DIVIDE LAS CALIFICACIONES EN PASADAS Y REPROBADAS PARA LI Y MA.MS
                and cr.sfrstcr_term_code = (select max(cr.sfrstcr_term_code ) from sfrstcr c2 where cr.sfrstcr_pidm = c2.sfrstcr_pidm ))
                And (DATOS.PIDM, datos.materia ) not in (select a.SFRSTCR_PIDM, b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB
                                                                                            from sfrstcr a, ssbsect b
                                                                                            Where  a.SFRSTCR_TERM_CODE =  b.SSBSECT_TERM_CODE
                                                                                            And a.SFRSTCR_CRN = b.SSBSECT_CRN
                                                                                            And a.SFRSTCR_RSTS_CODE = 'RE'
                                                                                            and ( a.SFRSTCR_GRDE_CODE in (select SHRGRDE_CODE
                                                                                                                                from SHRGRDE
                                                                                                                                Where SHRGRDE_LEVL_CODE = a.SFRSTCR_LEVL_CODE
                                                                                                                                 And  SHRGRDE_PASSED_IND ='Y'
                                                                                                                                 and  SHRGRDE_TERM_CODE_EFFECTIVE   = TERMATERIAS)
                                                                                                 or a.SFRSTCR_GRDE_CODE is null ))
                ORDER BY 1,6
        ) LOOP
         ---------------------se obtiene el porcentaje de avance del alumno para calcular el precio
        BEGIN
           SELECT Round(nvl(SZTHITA_AVANCE,0))
              INTO VDESC2
                FROM SZTHITA ZT
                WHERE ZT.SZTHITA_PIDM = JUMP.PIDM
                AND    ZT.SZTHITA_LEVL  = jump.nivel
                AND   ZT.SZTHITA_PROG   = JUMP.PROGRAMA  ;
                ----dbms_output.PUT_LINE('SALIDA AVANCE HITA  '|| VDESC2);
       EXCEPTION WHEN OTHERS THEN
        VDESC2 :=0;
                BEGIN
                   SELECT BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 ( JUMP.PIDM, JUMP.PROGRAMA )
                          INTO VDESC2
                     FROM DUAL;

                  --   --dbms_output.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
                  EXCEPTION WHEN OTHERS THEN
                   VDESC2 :=0;
                  END;
      END;
      -------------------OBTIENE EL COSTO------------
      BEGIN

                   select ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                      INTO VDESC, VCOSTO
                    from  ZSTPARA
                    where ZSTPARA_MAPA_ID = 'PORCENTAJE_NIVE'
                  --  and  ZSTPARA_PARAM_ID = jump.nivel
                    and  substr(ZSTPARA_PARAM_ID,1,2) =  jump.nivel -- 'LI'
                    and  substr(ZSTPARA_PARAM_ID,4) =  jump.CAMPUS -- 'UTL'
                    and round(VDESC2) between substr(ZSTPARA_PARAM_DESC,1,instr(ZSTPARA_PARAM_DESC,',',1)-1)
                    and  substr(ZSTPARA_PARAM_DESC,instr(ZSTPARA_PARAM_DESC,',',1)+1)
                    ;

                    ----dbms_output.PUT_LINE('SALIDA COSTOS_PARAMETROS  '|| VDESC ||'-'|| VCOSTO);
        EXCEPTION WHEN OTHERS THEN
           VDESC := '0';
          VCOSTO:= 0;
      END;


          IF  vcosto = 0  then
                              --SE CAMBIO LA VALIDACIÓN PARA QUE DE MANERA NATURAL TOMARA EL NIVEL GLOVICX 22/05/2021
          begin
                SELECT distinct nvl(MAX (svrrsso_serv_amount), 0)
                     INTO  VCOSTO2
                     FROM svrrsso a , tbbdetc tt,SVRRSRV r
                      WHERE  1=1
                        AND a.SVRRSSO_SRVC_CODE     = R.SVRRSRV_SRVC_CODE
                        and a.SVRRSSO_RSRV_SEQ_NO = R.SVRRSRV_SEQ_NO
                        and  a.svrrsso_srvc_code = 'NIVE'
                        and  a.SVRRSSO_DETL_CODE = tt.TBBDETC_DETAIL_CODE
                        AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(JUMP.PIDM),1,2)
                        and   r.SVRRSRV_LEVL_CODE =  jump.nivel    ;
          EXCEPTION WHEN OTHERS THEN
            VCOSTO2:= 0;
      END;


             ELSE
             VCOSTO2 := vcosto;
          end if;

--          ------excepcion especial para que los talleres los cobre de 2100 segun el parametrizador-----
--         begin
--           select ZSTPARA_PARAM_VALOR
--             into vparam_mate
--           FROM ZSTPARA
--              WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION'
--               and   ZSTPARA_PARAM_ID  = JUMP.MATERIA
--               AND ZSTPARA_PARAM_DESC  = JUMP.CAMPUS
--            ;
--
--          exception when others then
--             vparam_mate := VCOSTO2;
--          end;
--
--          if vparam_mate > 0 then
--            VCOSTO2 := vparam_mate;
--            else
--               VCOSTO2 := VCOSTO2 ;
--          end if;
         -------------------
     ----dbms_output.put_line('salida materias::  '||JUMP.MATERIA||'-'||JUMP.NOMBRE_MATERIA||'-'||JUMP.PROGRAMA||'-'||VCOSTO2||'-'||JUMP.PIDM||'--'||jump.nivel );
      ----se agrega la validacion para EXCLUIR LAS MATERIAS DE LOS TALLERES A TRAVES DEL PARAMETRIZADOR LO HIZO FERNANDO
      -----19/03/2020  GLOVICX
           BEGIN

                select 1--* --ZSTPARA_PARAM_VALOR as alum_sin_restriccio
                  INTO VTALLERES
                 from zstpara z
                  where 1=1
                      and Z.ZSTPARA_MAPA_ID  = 'SIN_MAT_MOODLE'
                      and z.ZSTPARA_PARAM_ID = JUMP.MATERIA
                      ;
           EXCEPTION WHEN OTHERS THEN
             VTALLERES := 0;
           END;
           ---SI EL VALOR DE VTALLERES ES UNO QUIERE DECIR QUE SE DEBE DE EXCLUIR  NO INSERTAR
           IF VTALLERES >= 1 THEN
             NULL; --AQUI LO EXCLUYO
           ELSE

                         INSERT INTO extraor2 ---------------se cambio este queri es el que presenta las materias reprobadas en el SSB -- VIC-- 28.06.2018
                          VALUES ( JUMP.MATERIA, --||'|'||VCOSTO2,
                                   JUMP.NOMBRE_MATERIA, --||' $ '||TO_CHAR(VCOSTO2,'999,999.00' ),
                                   JUMP.PROGRAMA,
                                   VCOSTO2,
                                   JUMP.PIDM);
                 COMMIT;
            END IF;

   END LOOP;

 --  END IF; --AQUI CIERRA EL IF DE UNICA--
    VSALIDA   := 'EXITO';
    RETURN   VSALIDA;

Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error :'||sqlerrm;
    -- insert into twpasow(valor1, valor2, valor3, valor6)
    ---   values( 'eroorro en fmateria_nive gral ',TO_CHAR(VCOSTO2,'L99G999D99MI' ),PPIDM,VSALIDA  );
    RETURN (VSALIDA);

END F_MATERIA_NIVE_UNI;


FUNCTION F_MATERIA_TISU_UNI (PPIDM NUMBER, pprogram varchar2 ) Return VARCHAR2  IS

  CONTADOR   NUMBER;
 VSALIDA    varchar2(300);
 VDESC       varchar2(30);
 VDESC2     NUMBER:=0;
 VCOSTO     NUMBER;
 VCOSTO2    NUMBER;
 vrango1    number;
 vrango2    number;
 vparam_mate    NUMBER;
 VTALLERES    NUMBER:=0;
 vcampus      varchar2(4);
 VFUNCION     varchar2(40);
 PACAMPUS     VARCHAR2(4);

BEGIN

         DELETE FROM extraor2
         WHERE  PIDM = PPIDM ;

----------------------aqui determinamos si el campus es unica o es utel glovicx 23/11/2020
FOR JUMP IN (
        select distinct datos.materia MATERIA, --||'|'||costo,
        --rpad(cc.SCRSYLN_LONG_COURSE_TITLE,40,'-') NOMBRE_MATERIA, --||' $ '|| costo,
        cc.SCRSYLN_LONG_COURSE_TITLE  NOMBRE_MATERIA,
        datos.programa AS PROGRAMA,
        -- nvl(datos.costo, 000)as costo,
        DATOS.PIDM AS PIDM
        ,datos.nivel as nivel
        ,datos.sp
        ,DATOS.CAMPUS
        from (
                SELECT (qq.ssbsect_subj_code || qq.ssbsect_crse_numb) materia
                --( select M.SZTMACO_MATPADRE from sztmaco m where M.SZTMACO_MATHIJO = qq.SSBSECT_SUBJ_CODE || qq.SSBSECT_CRSE_NUMB) materia,
                , CASE
                WHEN qq.ssbsect_seq_numb IS NULL
                THEN
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                ELSE
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                END nombre_materia,
                so.SORLCUR_PROGRAM as programa
                ,SO.SORLCUR_PIDM as pidm
                ,SO.SORLCUR_LEVL_CODE AS NIVEL
                ,'1' FINAL
                ,cr.SFRSTCR_STSP_KEY_SEQUENCE as Sp
                ,SO.SORLCUR_CAMP_CODE  AS CAMPUS
                FROM ssbsect qq, sfrstcr cr, shrgrde sh, sorlcur so, stvterm x, spriden sp
                ,(SELECT ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_ID, ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION' ) cos
                WHERE 1=1
                AND cr.sfrstcr_pidm = PPIDM
                AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                AND cr.sfrstcr_crn = qq.ssbsect_crn
                AND sh.shrgrde_code = cr.SFRSTCR_GRDE_CODE
                and sh.SHRGRDE_LEVL_CODE = cr.SFRSTCR_LEVL_CODE
                AND sh.shrgrde_passed_ind = 'N'
                and cr.SFRSTCR_GRDE_CODE is not null
                AND so.SORLCUR_LMOD_CODE = 'LEARNER'
                AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS')
                AND sh.shrgrde_levl_code = so.SORLCUR_LEVL_CODE
                AND cr.sfrstcr_pidm = so.sorlcur_pidm
                And so.sorlcur_program = pprogram
                And cr.SFRSTCR_STSP_KEY_SEQUENCE = so.SORLCUR_KEY_SEQNO
                AND so.sorlcur_term_code = x.stvterm_code
                AND sp.spriden_change_ind IS NULL
                and cr.sfrstcr_pidm = SP.SPRIDEN_PIDM
                and cos.ZSTPARA_PARAM_DESC(+) = qq.ssbsect_subj_code || qq.ssbsect_crse_numb
              /*  AND SO.SORLCUR_TERM_CODE  = (SELECT MAX (S2.SORLCUR_TERM_CODE  )  FROM SORLCUR S2
                                                 WHERE 1=1
                                                   AND  S2.SORLCUR_PROGRAM  = SO.SORLCUR_PROGRAM
                                                   AND  S2.SORLCUR_PIDM     =   SO.SORLCUR_PIDM   ) */

                minus
                SELECT qq.ssbsect_subj_code || qq.ssbsect_crse_numb materia
                , CASE
                WHEN qq.ssbsect_seq_numb IS NULL
                THEN
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                ELSE
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                END nombre_materia,
                so.SORLCUR_PROGRAM as programa
                ,SO.SORLCUR_PIDM as pidm
                ,SO.SORLCUR_LEVL_CODE AS NIVEL
                ,'2' FINAL
                ,cr.SFRSTCR_STSP_KEY_SEQUENCE as Sp
                  ,SO.SORLCUR_CAMP_CODE  AS CAMPUS
                FROM ssbsect qq, sfrstcr cr, sorlcur so, stvterm x, spriden sp
                ,(SELECT ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_ID, ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION' ) cos
                WHERE 1=1
                AND cr.sfrstcr_pidm = PPIDM --fget_pidm('010075696')
                AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                AND cr.sfrstcr_crn = qq.ssbsect_crn
                and cr.SFRSTCR_GRDE_CODE is null
                and cr.SFRSTCR_RSTS_CODE = 'RE'
                AND so.SORLCUR_LMOD_CODE = 'LEARNER'
                AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS')
                AND cr.sfrstcr_pidm = so.sorlcur_pidm
                And so.sorlcur_program = pprogram
                AND so.sorlcur_term_code = x.stvterm_code
                AND sp.spriden_change_ind IS NULL
                and cr.sfrstcr_pidm = SP.SPRIDEN_PIDM
                And cr.SFRSTCR_STSP_KEY_SEQUENCE = so.SORLCUR_KEY_SEQNO
                and cos.ZSTPARA_PARAM_DESC(+) = qq.ssbsect_subj_code || qq.ssbsect_crse_numb
               /*  AND SO.SORLCUR_TERM_CODE  = (SELECT MAX (S2.SORLCUR_TERM_CODE  )  FROM SORLCUR S2
                                                 WHERE 1=1
                                                   AND  S2.SORLCUR_PROGRAM  = SO.SORLCUR_PROGRAM
                                                   AND  S2.SORLCUR_PIDM     =   SO.SORLCUR_PIDM   ) */

                ) datos
               , SCRSYLN cc
                where 1=1
                and SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB = datos.materia
                 and datos.materia   in (SELECT ZSTPARA_PARAM_VALOR   FROM ZSTPARA  WHERE 1=1
                                            AND ZSTPARA_MAPA_ID = ('EXTRA_UNICA') )
                --AND SCBCRSE_CSTA_CODE = 'A'
                AND  EXISTS
                (SELECT 1
                FROM SVRSVPR p, SVRSVAD h
                WHERE p.SVRSVPR_SRVC_CODE in  ('EXTR' )
                AND P.SVRSVPR_PIDM = PPIDM --fget_pidm('010075696')
                AND p.SVRSVPR_SRVS_CODE in ('PA')--AQUI SOLO VA QUE SEA PAGADO RECUERDA QUE ES UN REQUISITO PARA PODER PEDIR TISU
                AND h.SVRSVAD_PROTOCOL_SEQ_NO = p.SVRSVPR_PROTOCOL_SEQ_NO
                --AND h.SVRSVAD_ADDL_DATA_CDE = datos.materia||'|'||costo) ----con este filtra que no se solicite una materia que ya fue solicitada
                --AND substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1) = datos.materia
                 AND SVRSVAD_ADDL_DATA_CDE =  datos.materia )
                AND NOT EXISTS(  --AQUI PONEMOS ESTE FILTRO PARA QUE NO SE PETITA MA TAREA
               SELECT 1
                FROM SVRSVPR p, SVRSVAD h
                WHERE p.SVRSVPR_SRVC_CODE  in  ('TISU' )
                AND P.SVRSVPR_PIDM = PPIDM --fget_pidm('010075696')
                AND p.SVRSVPR_SRVS_CODE  in ('PA', 'AC')--se quito la validacion de "PA" a peticion de Fernando el dia 05/12/2019
                AND h.SVRSVAD_PROTOCOL_SEQ_NO = p.SVRSVPR_PROTOCOL_SEQ_NO
               -- AND h.SVRSVAD_ADDL_DATA_CDE = datos.materia||'|'||costo) ----con este filtra que no se solicite una materia que ya fue solicitada
              -- AND substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1) = datos.materia
                 AND SVRSVAD_ADDL_DATA_CDE =  datos.materia       )
               /* and datos.materia NOT in ( select SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB
                FROM ssbsect qq, sfrstcr cr, shrgrde SH
                WHERE 1=1
                AND cr.sfrstcr_pidm = PPIDM --fget_pidm('010075696')
                AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                AND cr.sfrstcr_crn = qq.ssbsect_crn
                and ( cr.SFRSTCR_GRDE_CODE in ('6.0','7.0','8.0','9.0','10.0')
                or cr.SFRSTCR_GRDE_CODE is null )
                AND CR.SFRSTCR_GRDE_CODE = SH.SHRGRDE_CODE
                AND CR.SFRSTCR_LEVL_CODE = SH.SHRGRDE_LEVL_CODE
                AND shrgrde_passed_ind = 'Y' ---------ESTO DIVIDE LAS CALIFICACIONES EN PASADAS Y REPROBADAS PARA LI Y MA.MS
                and cr.sfrstcr_term_code = (select max(cr.sfrstcr_term_code ) from sfrstcr c2 where cr.sfrstcr_pidm = c2.sfrstcr_pidm ))
                And (DATOS.PIDM, datos.materia ) not in (select a.SFRSTCR_PIDM, b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB
                                                                                            from sfrstcr a, ssbsect b
                                                                                            Where  a.SFRSTCR_TERM_CODE =  b.SSBSECT_TERM_CODE
                                                                                            And a.SFRSTCR_CRN = b.SSBSECT_CRN
                                                                                            And a.SFRSTCR_RSTS_CODE = 'RE'
                                                                                            and ( a.SFRSTCR_GRDE_CODE in (select SHRGRDE_CODE
                                                                                                                                                from SHRGRDE
                                                                                                                                                Where SHRGRDE_LEVL_CODE = a.SFRSTCR_LEVL_CODE
                                                                                                                                                And SHRGRDE_PASSED_IND ='Y')

                                                                                                 or a.SFRSTCR_GRDE_CODE is null ))  */

                ORDER BY 1,6
        ) LOOP
         ---------------------se obtiene el porcentaje de avance del alumno para calcular el precio
        BEGIN
           SELECT ROUND(nvl(SZTHITA_AVANCE,0))
              INTO VDESC2
                FROM SZTHITA ZT
                WHERE ZT.SZTHITA_PIDM = JUMP.PIDM
                AND    ZT.SZTHITA_LEVL  = jump.nivel
                AND   ZT.SZTHITA_PROG   = JUMP.PROGRAMA  ;
                ----dbms_output.PUT_LINE('SALIDA AVANCE HITA  '|| VDESC2);
       EXCEPTION WHEN OTHERS THEN
        VDESC2 :=0;
                BEGIN
                   SELECT BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 ( JUMP.PIDM, JUMP.PROGRAMA )
                          INTO VDESC2
                     FROM DUAL;

                  --   --dbms_output.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
                  EXCEPTION WHEN OTHERS THEN
                   VDESC2 :=0;
                  END;
      END;
      -------------------OBTIENE EL COSTO------------
      BEGIN

                   select ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                      INTO VDESC, VCOSTO
                    from  ZSTPARA
                    where ZSTPARA_MAPA_ID = 'PORCENTAJE_NIVE'
                  --  and  ZSTPARA_PARAM_ID = jump.nivel
                    and  substr(ZSTPARA_PARAM_ID,1,2) =  jump.nivel -- 'LI'
                    and  substr(ZSTPARA_PARAM_ID,4) =  jump.CAMPUS -- 'UTL'
                    and  round(VDESC2) between substr(ZSTPARA_PARAM_DESC,1,instr(ZSTPARA_PARAM_DESC,',',1)-1)
                    and  substr(ZSTPARA_PARAM_DESC,instr(ZSTPARA_PARAM_DESC,',',1)+1)
                    ;

                    ----dbms_output.PUT_LINE('SALIDA COSTOS_PARAMETROS  '|| VDESC ||'-'|| VCOSTO);
        EXCEPTION WHEN OTHERS THEN
           VDESC := '0';
          VCOSTO:= 0;
      END;


          IF  vcosto = 0  then
                      --SE CAMBIO LA VALIDACIÓN PARA QUE DE MANERA NATURAL TOMARA EL NIVEL GLOVICX 22/05/2021
                 begin
                    SELECT distinct nvl(MAX (svrrsso_serv_amount), 0)
                     INTO  VCOSTO2
                     FROM svrrsso a , tbbdetc tt,SVRRSRV r
                      WHERE  1=1
                        AND a.SVRRSSO_SRVC_CODE     = R.SVRRSRV_SRVC_CODE
                        and a.SVRRSSO_RSRV_SEQ_NO = R.SVRRSRV_SEQ_NO
                        and  a.svrrsso_srvc_code = 'NIVE'
                        and  a.SVRRSSO_DETL_CODE = tt.TBBDETC_DETAIL_CODE
                        AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(JUMP.PIDM),1,2)
                        and   r.SVRRSRV_LEVL_CODE =  jump.nivel    ;
                EXCEPTION WHEN OTHERS THEN
                    VCOSTO2:= 0;
                END;

             ELSE
             VCOSTO2 := vcosto;
          end if;

--          ------excepcion especial para que los talleres los cobre de 2100 segun el parametrizador-----
--         begin
--           select ZSTPARA_PARAM_VALOR
--             into vparam_mate
--           FROM ZSTPARA
--              WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION'
--               and   ZSTPARA_PARAM_ID  = JUMP.MATERIA
--               AND ZSTPARA_PARAM_DESC  = JUMP.CAMPUS
--            ;
--
--          exception when others then
--             vparam_mate := VCOSTO2;
--          end;
--
--          if vparam_mate > 0 then
--            VCOSTO2 := vparam_mate;
--            else
--               VCOSTO2 := VCOSTO2 ;
--          end if;
         -------------------
     ----dbms_output.put_line('salida materias::  '||JUMP.MATERIA||'-'||JUMP.NOMBRE_MATERIA||'-'||JUMP.PROGRAMA||'-'||VCOSTO2||'-'||JUMP.PIDM||'--'||jump.nivel );
      ----se agrega la validacion para EXCLUIR LAS MATERIAS DE LOS TALLERES A TRAVES DEL PARAMETRIZADOR LO HIZO FERNANDO
      -----19/03/2020  GLOVICX
           BEGIN

                select 1--* --ZSTPARA_PARAM_VALOR as alum_sin_restriccio
                  INTO VTALLERES
                 from zstpara z
                  where 1=1
                      and Z.ZSTPARA_MAPA_ID  = 'SIN_MAT_MOODLE'
                      and z.ZSTPARA_PARAM_ID = JUMP.MATERIA
                      ;
           EXCEPTION WHEN OTHERS THEN
             VTALLERES := 0;
           END;
           ---SI EL VALOR DE VTALLERES ES UNO QUIERE DECIR QUE SE DEBE DE EXCLUIR  NO INSERTAR
           IF VTALLERES >= 1 THEN
             NULL; --AQUI LO EXCLUYO
           ELSE

                         INSERT INTO extraor2 ---------------se cambio este queri es el que presenta las materias reprobadas en el SSB -- VIC-- 28.06.2018
                          VALUES ( JUMP.MATERIA, --||'|'||VCOSTO2,
                                   JUMP.NOMBRE_MATERIA , --||' $ '||TO_CHAR(VCOSTO2,'999,999.00' ),
                                   JUMP.PROGRAMA,
                                   VCOSTO2,
                                   JUMP.PIDM);
                 COMMIT;
            END IF;

   END LOOP;

 --  END IF; --AQUI CIERRA EL IF DE UNICA--
    VSALIDA   := 'EXITO';
    RETURN   VSALIDA;

Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error :'||sqlerrm;
    -- insert into twpasow(valor1, valor2, valor3, valor6)
    ---   values( 'eroorro en fmateria_nive gral ',TO_CHAR(VCOSTO2,'L99G999D99MI' ),PPIDM,VSALIDA  );
    RETURN (VSALIDA);

END F_MATERIA_TISU_UNI;

FUNCTION F_telefono ( PPIDM NUMBER )  Return PKG_SERV_SIU.datos_telf_type
IS

----- FUNCION PARA MOSTRAR LOS TELEFONOS QUE EXITEN POR ALUMNO PARA, proyecto de ADD CAMPOS NUEVOS NIVE
 CUR_telefonos BANINST1.PKG_SERV_SIU.datos_telf_type;


BEGIN

 open CUR_telefonos for
                        select distinct SPRTELE_PHONE_AREA||'-'||SPRTELE_PHONE_NUMBER telefonos
                        from SPRTELE
                        where 1=1
                        and SPRTELE_PIDM = PPIDM
                         and SPRTELE_TELE_CODE in ('CELU','RESI');

   return CUR_telefonos;
  Exception
    When others  then
       vl_error := 'PKG_SERV_SIU_ERROR.CUR_telefonos: ' || sqlerrm;
   return CUR_telefonos;

END F_telefono;


FUNCTION F_inserta_new_mail( PPIDM NUMBER, PEMAIL  varchar2 )  Return  varchar2  IS
-- SI YA EXISTE NO HACE NADA
-- SI NO EXISTE ENTONCES LO INSERTA EN GOREMAL BAJO LA ETIQUETA DE "AUTO"     proyecto de ADD CAMPOS NUEVOS NIVE
-- GLOVICX 22/02/021
--PARAMETROS DE ENTRADA
--PPIDM  NUMBER;
--PEMAIL  VARCHAR2(50);
VEXISTE_MAIL    NUMBER:=0;
P_EMAL_CODE    varchar2(12);
vsalida     VARCHAR2(150);

BEGIN

--ppidm := 2156;
--pemail := 'carlaceciliacejudo@live.com.mx';
P_EMAL_CODE   := 'AUTO';

--1RO VALIDAMOS QUE NO EXISTA EL EMAIL QUE SE INSERTO.
    BEGIN

        SELECT 1
         INTO VEXISTE_MAIL
        FROM GOREMAL
        WHERE 1=1
         AND GOREMAL_PIDM = PPIDM
         AND GOREMAL_EMAIL_ADDRESS = PEMAIL;

     EXCEPTION WHEN OTHERS THEN

     VEXISTE_MAIL  := 0;
     END;

  -- --dbms_output.PUT_LINE('EL MAIL INGRESADO EXISTE O NO ?  ' ||VEXISTE_MAIL||'--'||pemail );

        IF VEXISTE_MAIL = 0  THEN  -- ESE EMAIL ES NUEVO Y SE ANEXA ALA TABLA PERO COMO NO PREFERIDO


           BEGIN
           GB_EMAIL.P_CREATE(p_pidm => PPIDM,
                            p_emal_code => P_EMAL_CODE ,
                            p_email_address =>PEMAIL,
                            p_preferred_ind => 'N',
                            p_rowid_out => vsalida);
             EXCEPTION WHEN OTHERS THEN
             vsalida  := SQLERRM;
             ----dbms_output.PUT_LINE('ERROR DE FUNCIONO ?  ' ||vsalida);
             END;

        END IF;


/*
  IF vsalida IS NOT NULL  OR VEXISTE_MAIL = 1 THEN ---ES UN EXITO
  ----dbms_output.PUT_LINE('SALIDA DEL INSERT EMAIL '|| vsalida );
    null;
  -- RETURN ('EXITO');

  ELSE
 -- --dbms_output.PUT_LINE('SALIDA DEL EMAIL ya existe '|| vsalida );
  null;
   --RETURN ('ERROR');

  END IF;
*/

  RETURN ('EXITO');


EXCEPTION WHEN OTHERS THEN
 NULL;
RETURN ('Error en f_insert_new_mail');
END F_inserta_new_mail;



FUNCTION F_INSERTA_NEW_TELF (PPIDM number, Ptelf varchar2  ) RETURN VARCHAR2 IS


----ESTA FUNCION ES PARA ALMOMENTO DE INSERTAR UN NUEVO MAIL EN LA NIVELACION SE VALIDE SI EXISTE O NO  proyecto de ADD CAMPOS NUEVOS NIVE
-- SI YA EXISTE NO HACE NADA
-- SI NO EXISTE ENTONCES LO INSERTA EN GOREMAL BAJO LA ETIQUETA DE "AUTO"
-- GLOVICX 22/02/021
--PARAMETROS DE ENTRADA
--PPIDM  NUMBER;
--Ptelf  VARCHAR2(50);
VEXISTE_telf    NUMBER:=0;
P_TELF_CODE    varchar2(12);
vsalida     VARCHAR2(50);
PCODE      VARCHAR2(10);
PTELEFON   VARCHAR2(15);
vnum_sal   NUMBER;
vl_error   VARCHAR2(200);

BEGIN

--ppidm := 265;
--Ptelf := '52--044555522999';
P_TELF_CODE   := 'AUTO';

--  ---SE TIENE QUE SEPARAR ESTA VARIABLE Ptelf POR CODIGO DE ESTADO Y TELF

PCODE := SUBSTR(Ptelf,1, 2 );
PTELEFON  := SUBSTR(Ptelf,3,8);


----dbms_output.PUT_LINE( 'RECUPERA CODiGO Y TELEFONO '||PCODE ||'--'|| PTELEFON);

--1RO VALIDAMOS QUE NO EXISTA EL TEFELONO QUE SE INSERTO.
    BEGIN

        SELECT 1
         INTO VEXISTE_telf
        FROM SPRTELE
        WHERE 1=1
         AND SPRTELE_PIDM = PPIDM
         AND SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER LIKE ('%'|| Ptelf);

     EXCEPTION WHEN OTHERS THEN

     VEXISTE_telf  := 0;
     END;

 --  --dbms_output.PUT_LINE('EL TELEFONO INGRESADO EXISTE O NO ?  ' ||VEXISTE_telf||'--'||Ptelf );

        IF VEXISTE_telf = 0  THEN  -- ESE EMAIL ES NUEVO Y SE ANEXA ALA TABLA PERO COMO NO PREFERIDO

            BEGIN
                          GB_TELEPHONE.P_CREATE(p_pidm => PPIDM,
                                          p_tele_code => P_TELF_CODE,
                                          p_phone_area => PCODE,
                                          p_phone_number => PTELEFON,
                                          p_primary_ind => 'Y',
                                          p_rowid_out => vsalida,
                                          p_seqno_out => vnum_sal);
           --Return vl_error;
               ----dbms_output.PUT_LINE('ESTOY DEL INSERT TELEFONO '|| vsalida||'-'||vnum_sal );
               EXCEPTION
                        WHEN OTHERS THEN
                            vl_error := 'Error : '||sqlerrm;
               --      Return vl_error;

                 ----dbms_output.PUT_LINE('ERROR EN INSERT TELF  '|| vl_error );
               END;

        END IF;


--
--  IF vsalida IS NOT NULL  THEN ---ES UN EXITO
--    null;
--
--  --dbms_output.PUT_LINE('SALIDA DEL INSERT TELEFONO '|| vsalida||'-'||vnum_sal );
--   RETURN ('EXITO');
--
--  ELSE
--  null;
--
--
--  --dbms_output.PUT_LINE('SALIDA DEL TELEFONO ya existe '|| vsalida||'-'||vnum_sal );
--  RETURN ('ERROR');
--  END IF;
--

   RETURN ('EXITO');

EXCEPTION WHEN OTHERS THEN
 NULL;
RETURN ('Error en finserta_new_telf');

END F_INSERTA_NEW_TELF;




FUNCTION F_COSTO_ENVIO (PPCODE VARCHAR2,Pstst VARCHAR2,Pcamp VARCHAR2,Plevel VARCHAR2, p_delivery_type VARCHAR2   ) RETURN NUMBER IS

vimporte_envio  NUMBER:= 0;

BEGIN


        SELECT  distinct  STVWSSO_CHRG
                into vimporte_envio
              FROM SVRRSSO SS, STVWSSO W,SVRRSRV
               WHERE 1=1
                AND UPPER(SS.SVRRSSO_SRVC_CODE) = UPPER(PPCODE)
                AND svrrsrv_stst_code = Pstst
                AND svrrsrv_camp_code = Pcamp
                AND svrrsrv_levl_code = Plevel
                AND SVRRSRV_SRVC_CODE = SVRRSRV_SRVC_CODE
                AND SVRRSRV_SEQ_NO    = SVRRSSO_RSRV_SEQ_NO
                AND SVRRSSO_WSSO_CODE = STVWSSO_CODE
                AND SVRRSSO_WSSO_CODE = p_delivery_type;

RETURN vimporte_envio;

 exception when others then
               vl_error := 'PKG_SERV_SIU_ERROR.F_COSTO_ENVIO: ' || sqlerrm;
               vimporte_envio:= 0;

        ----dbms_output.put_line( vl_error );

END F_COSTO_ENVIO ;


FUNCTION F_INSERT_CARTERA (PCODE VARCHAR2, PPIDM NUMBER, LTERM VARCHAR2,vcodigo_dtl VARCHAR2,vmonto NUMBER, VDESC_DTL VARCHAR2,PNO_SERV NUMBER,VNO_DOCTO VARCHAR2,
                        f_inicio VARCHAR2,Vstudy VARCHAR2,Vpparte VARCHAR2, vcode_curr VARCHAR2 ,pfeed varchar2 ,ptranpay number  )  RETURN VARCHAR2 IS
-- se hace un cambio para NIVE CERO 3ra vercion para las condonaciones y fechas de entre date glovicx 25.05.2025

VSALIDA             VARCHAR2(200):= 'EXITO';
lv_trans_number2    NUMBER:=0;
vmonto2             NUMBER:=0;
vaccesorio          varchar2(100);
VNIVE_CERO          NUMBER:=0;
VFECHA_EFECTIVA     date;
vnive_status        varchar2(6);
VTRANS_DATE         date;


BEGIN


    BEGIN
        SELECT NVL (MAX (TZRACCD_tran_number), 0) + 1
               INTO lv_trans_number2
               FROM tzraccd
              WHERE TZRACCD_pidm = PPIDM;
         EXCEPTION WHEN OTHERS THEN
           VSALIDA:='Error :'||sqlerrm;
            lv_trans_number2 := 0;

        END;

    -- para el proyecto de mes gratis yo envio el monto en negativo pero solo va el saldo en negativo
   -- aqui hacemos la conversion de cada uno
    begin


        select distinct 'Y'
        INTO vaccesorio
        from zstpara
        where 1=1
        AND SUBSTR(F_GetSpridenID(Ppidm),1,2)||ZSTPARA_PARAM_DESC = vcodigo_dtl
        and ZSTPARA_MAPA_ID  = 'MES_GRATIS'
        and ZSTPARA_PARAM_ID = PCODE;

    exception when others then

      vaccesorio  := 'N';
     end;


   IF vaccesorio = 'Y' then
      vmonto2  := (vmonto)*-1 ;

      else
        vmonto2 := vmonto;

   end if;

   IF PCODE = 'NIVE' then
   
      
     BEGIN
        select count(1), SVRSVPR_SRVS_CODE
          into VNIVE_CERO, vnive_status
        from svrsvpr v
        where 1=1
        anD V.SVRSVPR_PIDM    = PPIDM
        and V.SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
        ANd V.SVRSVPR_SRVC_CODE = pcode
       -- AND V.SVRSVPR_SRVS_CODE = 'PP'
        and V.SVRSVPR_STEP_COMMENT = 'NIVE_CERO'
        group by SVRSVPR_SRVS_CODE
        ;
  
     EXCEPTION WHEN OTHERS THEN
     VNIVE_CERO := 0;
     
     END;
     
     --dbms_output.put_line('antes de cambio nieve cero  '||vnive_status || VTRANS_DATE ||'-'|| VFECHA_EFECTIVA||'-'|| f_inicio  );
     IF VNIVE_CERO > 0  and vnive_status = 'EC' THEN  -- aqui esta insertando el cargo la primera vez que compra
     
     null;   
     --VTRANS_DATE     := to_date(to_char(f_inicio,'DD/MM/YYYY'),'DD/MM/YYYY') + 22 ;
     --VFECHA_EFECTIVA := to_date(f_inicio,'DD/MM/YYYY') + 22 ;
      --- para el caso de nive cero se le suman 22 dias mas a la fecha de TBRACCD_EFFECTIVE_DATE glovicx 11.02.2025
          
        --VFECHA_EFECTIVA    :=  to_date(f_inicio,'DD/MM/RR')  + 22 ;
        VFECHA_EFECTIVA := to_date(f_inicio,'DD/MM/YYYY') ;
       VFECHA_EFECTIVA := VFECHA_EFECTIVA + 22;
        
        VTRANS_DATE        :=  VFECHA_EFECTIVA;
       
    
    elsif VNIVE_CERO > 0  and vnive_status = 'EN' THEN   -- segundaparte hay una condonacion de nivelacion 
     null;
     vmonto2   := (vmonto)*-1;    
     
     else
     ---aqui es una transaccion de otro accesroio  
        VTRANS_DATE     :=  sysdate;
        VFECHA_EFECTIVA := sysdate;
        
      -- dbms_output.put_line('antes de cambio nieve cero  '||vnive_status || VTRANS_DATE ||'-'|| VFECHA_EFECTIVA||'-'|| f_inicio  );
    END IF;
 --  dbms_output.put_line('DESPUES  de cambio nieve ceroXX  '||vnive_status ||'-'|| VTRANS_DATE ||'-'|| VFECHA_EFECTIVA||'-'|| vmonto  );
   
   else
    ---aqui es una transaccion de otro accesroio  
        VTRANS_DATE     :=  sysdate;
        VFECHA_EFECTIVA := sysdate;
    
   end if;

--dbms_output.put_line('DESPUES  de cambio nieve ceroXX  '||vnive_status ||'-'|| VTRANS_DATE ||'-'|| VFECHA_EFECTIVA||'-'|| vmonto  );
                begin
                             INSERT INTO tzraccd (TZRACCD_PIDM,
                                          TZRACCD_TERM_CODE,
                                          TZRACCD_DETAIL_CODE,
                                          TZRACCD_USER,
                                          TZRACCD_ENTRY_DATE,
                                          TZRACCD_AMOUNT,
                                          TZRACCD_BALANCE,
                                          TZRACCD_EFFECTIVE_DATE,
                                          TZRACCD_DESC,
                                          TZRACCD_CROSSREF_NUMBER,
                                          TZRACCD_SRCE_CODE,
                                          TZRACCD_ACCT_FEED_IND,
                                          TZRACCD_SESSION_NUMBER,
                                          TZRACCD_DATA_ORIGIN,
                                          TZRACCD_TRAN_NUMBER,
                                          TZRACCD_ACTIVITY_DATE,
                                          TZRACCD_MERCHANT_ID,
                                          TZRACCD_TRANS_DATE,
                                          TZRACCD_DOCUMENT_NUMBER
                                         ,TZRACCD_FEED_DATE
                                         ,TZRACCD_STSP_KEY_SEQUENCE
                                         ,TZRACCD_PERIOD
                                         ,TZRACCD_CURR_CODE
                                         ,TZRACCD_FEED_DOC_CODE
                                         ,TZRACCD_TRAN_NUMBER_PAID
                                          )
                          VALUES (PPIDM,
                                  LTERM,
                                  vcodigo_dtl, --VCODE_DTL,
                                  'WWW_SIU',
                                  SYSDATE,
                                  vmonto,
                                  vmonto2,
                                   trunc(VFECHA_EFECTIVA) , 
                                  VDESC_DTL,
                                  PNO_SERV,
                                  'T',
                                  'Y',
                                  0,
                                  'WEB-STUOSSR',
                                  lv_trans_number2,
                                  SYSDATE,
                                  NULL,
                                  TRUNC(VTRANS_DATE) , 
                                  substr(VNO_DOCTO,1,8)
                                  ,f_inicio
                                  ,Vstudy
                                  ,Vpparte
                                  ,vcode_curr
                                  ,pfeed
                                  ,ptranpay);
               exception when others then
                      VSALIDA:='Error :'||sqlerrm;
                    --dbms_output.PUT_LINE('ERROOR EN f_insert_TZRACCD1:.  ' || VSALIDA );
               end;

     ---COMMIT;
     -----------se inserta directamente en tbraccd solo para TODOS  los servicios ---- glovicx

          -----------------------VUELVE A CALCULAR EL TRAN_NUMBER POR QUE NO COINCIDEN CON LA TABLA DE PASO
         BEGIN
        SELECT NVL (MAX (tbraccd_tran_number), 0) + 1
               INTO lv_trans_number2
               FROM tbraccd
              WHERE tbraccd_pidm = PPIDM;
              
         EXCEPTION WHEN OTHERS THEN
          --- VSALIDA:='Error :'||sqlerrm;
            lv_trans_number2 := 0;

        END;

        dbms_output.put_line('antes '||Vpparte );
        
       BEGIN
      INSERT INTO TBRACCD (TBRACCD_PIDM,
                  TBRACCD_TERM_CODE,
                  TBRACCD_DETAIL_CODE,
                  TBRACCD_USER,
                  TBRACCD_ENTRY_DATE,
                  TBRACCD_AMOUNT,
                  TBRACCD_BALANCE,
                  TBRACCD_EFFECTIVE_DATE,
                  TBRACCD_DESC,
                  TBRACCD_CROSSREF_NUMBER,
                  TBRACCD_SRCE_CODE,
                  TBRACCD_ACCT_FEED_IND,
                  TBRACCD_SESSION_NUMBER,
                  TBRACCD_DATA_ORIGIN,
                  TBRACCD_TRAN_NUMBER,
                  TBRACCD_ACTIVITY_DATE,
                  TBRACCD_MERCHANT_ID,
                  TBRACCD_TRANS_DATE,
                  TBRACCD_DOCUMENT_NUMBER
                 ,TBRACCD_FEED_DATE
                 ,TBRACCD_STSP_KEY_SEQUENCE
                 ,TBRACCD_PERIOD
                 ,TBRACCD_CURR_CODE
                  ,TBRACCD_FEED_DOC_CODE
                  ,TBRACCD_TRAN_NUMBER_PAID
                    )
          VALUES (PPIDM,
                  LTERM,
                  vcodigo_dtl, --VCODE_DTL,
                  'WWW_SIU',
                  SYSDATE,
                  vmonto,
                  vmonto2,
                  trunc(VFECHA_EFECTIVA) ,
                  VDESC_DTL,
                  PNO_SERV,
                  'T',
                  'Y',
                  0,
                  'WEB-STUOSSR',
                  lv_trans_number2,
                  SYSDATE,
                  NULL,
                  trunc ( VTRANS_DATE) ,
                  substr(VNO_DOCTO,1,8)
                  ,f_inicio
                  ,Vstudy
                  ,TRIM(Vpparte)
                  ,vcode_curr
                  ,pfeed
                  ,ptranpay);

        ----dbms_output.PUT_LINE('INSERTA  EN TBRACCD:.  ' ||J||' --'|| vcodigo_dtl||'-'||VDESC_DTL||'-'||PNO_SERV );

        Exception When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
        VSALIDA:='Error :'||sqlerrm;
        ----dbms_output.PUT_LINE('ERROOR EN TBRACCD:.  ' || VSALIDA );
      END ;


commit;

RETURN ( VSALIDA||'|'||lv_trans_number2 );
exception when others then
VSALIDA := sqlerrm;
--insert into twpasow ( valor1, valor2, valor3,valor4)
--values ('error en inserta  tbraccd',PPIDM, PNO_SERV,VSALIDA );

END F_INSERT_CARTERA;


FUNCTION F_VALIDA_COLF_NIVEL (ppidm number, pcode varchar2, pcampus varchar2, pprograma varchar2  ) RETURN VARCHAR2 IS


--glovicx 20/05/021
--esta funcion se hizo para validar si el nuevo accesorio de COLF se puede o no comprar las validaciones son NIVEL programa con los nuevos codigos detalle
---esto son los parametros que entran en la función de inserta servicio
--Ppidm in NUMBER, PCODE  IN VARCHAR2 , pPeriodo IN VARCHAR2, Pimporte VARCHAR2, PCAMPUS VARCHAR2,PPCOMENT VARCHAR2
--                      ,pcve_envio varchar2 , PPROGRAMA  VARCHAR2
--Ppidm       number:= 151442;
--PCODE       VARCHAR2(4):= 'COLF';
--PCAMPUS     VARCHAR2(4):= 'UTL';
--PPROGRAMA   VARCHAR2 (14):= 'UTLLIPPFED';
VNIVEL      varchar2(4);
vsp         number;
VPROGRAMA2  VARCHAR2 (14);
pcve_envio  VARCHAR2 (4);
VSALIDA     number;

begin
null;
/*------
1.- preguntamos por nivel sacamos el codigo de detalle.
2.- validamos que no haya un cargo con ese codigo de detalle que esta insertando
3.- si no existe lo dejamos pasar sin problemas
4.- si ya existe validamos el study path para saber de que programa es el cargo
5.- si es el mismo programa entonces NO pasa
6.- si es una programa nuevo o diferente del primero entonces si lo deja pasar.

regreso a la funcion original el estatus si pasa ó no.

*/
--PARA PROYECTO QUE SE PUEDA HACER COLF POR NIVEL GLOVICX 18/05/021
              BEGIN
                select NIVEL, sp
                    INTO VNIVEL, vsp
                from tztprog
                where 1=1
                and PROGRAMA  = PPROGRAMA
                and pidm = PPIDM;
              EXCEPTION WHEN OTHERS THEN
                VNIVEL := NULL;
               END;


  ----dbms_output.put_line('calcula nivel y SP del programa ACTUAL '|| VNIVEL ||'-'||vsp );

-- si Vsalida = 1 se tiene que evaluar el programa para ver que sea un SP o programa diferente
      BEGIN
         select DISTINCT SVRSVAD_ADDL_DATA_CDE as descrt
           INTO VPROGRAMA2
            from svrsvpr v,SVRSVAD VA
            where 1=1
              and SVRSVPR_SRVC_CODE = 'COLF'
              AND  SVRSVPR_PIDM  = PPIDM
               and  SVRSVPR_SRVS_CODE != 'CA'---NOT IN ('AC','PA')
              and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
              and va.SVRSVAD_ADDL_DATA_SEQ = '1'
              and SVRSVAD_ADDL_DATA_CDE  = PPROGRAMA  --se le agrega esta validación y con eso busca el programa que viene del parametro valida si existe
           order by 1 desc  ;
      exception when others then
      VPROGRAMA2 := null;
      END;
      ----dbms_output.put_line('calcula el programa ANTERIOR DE COLF1  '|| VPROGRAMA2 );
  --VALIDA LOS PROGRAMAS
 --
       --LOS PROGRAMAS CON DIFERENTES en teoria lo debe sejar pasar
 ----dbms_output.put_line('evalua programa ANTERIOR VS nuevo  '|| VPROGRAMA2 ||'-'||PPROGRAMA);

--AHORA SE VALIDA POR CODIGODE DETALLE POR QUE SI PUEDE TENER MAS DE UNO PERO DE DIFERENTE NIVEL
           BEGIN

             select distinct TBRACCD_CROSSREF_NUMBER
             INTO  VSALIDA
                    from tbraccd
                    where 1=1
                    and tbraccd_pidm = Ppidm
                    and TBRACCD_DETAIL_CODE = (select DISTINCT (o2.SVRRSSO_DETL_CODE)
                                                     from SVRRSSO o2 ,SVRRSRV r
                                                        WHERE  1=1
                                                        AND o2.SVRRSSO_SRVC_CODE     = R.SVRRSRV_SRVC_CODE
                                                        and O2.SVRRSSO_RSRV_SEQ_NO   = R.SVRRSRV_SEQ_NO
                                                        AND O2.SVRRSSO_SRVC_CODE     = PCODE
                                                        and r.SVRRSRV_LEVL_CODE      = VNIVEL
                                                     --   and   SVRRSSO_WSSO_CODE      = pcve_envio
                                                        and substr(SVRRSSO_DETL_CODE,1,2)   =  SUBSTR(F_GetSpridenID(Ppidm),1,2) )
                    and (TBRACCD_DOCUMENT_NUMBER != 'WCANCE'
                          OR  TBRACCD_DOCUMENT_NUMBER is null)
                    and TBRACCD_STSP_KEY_SEQUENCE  = vsp;

            exception when others then
             VSALIDA := 0;
               ----dbms_output.put_line('errorn en tbracce NO entra == '|| Ppidm||'-'||PCODE||'-'||VNIVEL||'-'||pcve_envio  );
           END;
     ----dbms_output.put_line('si salida es cero SI ENTRA  <> NO entra == '|| VSALIDA );
-- si VSALIDA = 0 quiere decir que no existe un COLF para ese nivel.

--se podria hacer una nueva validacion de los programas que no sena iguales y que no este cancelado como para amarrar


 IF    VPROGRAMA2 IS NULL  and VSALIDA = 0 THEN
   ----dbms_output.put_line('ULTIMA EVALUACION FUNCION1  == '||PPROGRAMA ||'-'|| VPROGRAMA2 ||'-'|| VSALIDA );
 RETURN (VSALIDA);

 ELSIF PPROGRAMA != VPROGRAMA2 and VSALIDA = 0 THEN
 ----dbms_output.put_line('ULTIMA EVALUACION FUNCION 2 == '||PPROGRAMA ||'-'|| VPROGRAMA2 ||'-'|| VSALIDA );
 RETURN (VSALIDA);
 ELSE
   ----dbms_output.put_line('ULTIMA EVALUACION FUNCION 3 == '||PPROGRAMA ||'-'|| VPROGRAMA2 ||'-'|| VSALIDA );
 RETURN('LA COLF YA EXISTE');

 end if;




exception when others then
null;
VSALIDA := sqlerrm;
----dbms_output.put_line('error gral en F_VALIDA_COLF_NIVEL ');

END F_VALIDA_COLF_NIVEL ;



FUNCTION F_accesorio_costo_cero (ppidm number, pcode varchar2, pcampus varchar2, pprograma varchar2  ) RETURN VARCHAR2 IS
/*
este proceso se realiza para los accesorios que esta comprando los alumnos que pero ya pago en su PAKETE de VTAS
esta funcion me dice si ya lo adquirio
se puede pedir una ves sin costo so lo vuelve a pedir entonces se va por via normal
si es la primera ves que lo pide entonces solo siembra el accesorio con estatus de PAGADO
pero no hace nada de cartera
glovicx 02/08/2021
si pcampus    es nulo es toy validadndo el precio
se cambiaron la etiquetas el 25/08/021
TUIL    LICENCIATURA
TUIM   MAESTRÍA
--AJUSTE PARA TITULOS INTER QUE SE duplicaban glovicx 18.06.2024
*/

v_no_trans   number:=0;
v_COUNT_trans   number:=0;
VMONTO       number:=0;
v_etiqueta   varchar2(2);
v_code_dtl   varchar2(3);
v_code_etiq  varchar2(5);
VNIVEL        varchar2(5);
vsp           varchar2(5);

begin
------con el programa buscamos su SP

            BEGIN
                select NIVEL, sp
                    INTO VNIVEL, vsp
                from tztprog
                where 1=1
                and PROGRAMA  = nvl(PPROGRAMA, PROGRAMA)
                and pidm      = PPIDM;

              EXCEPTION WHEN OTHERS THEN
                VNIVEL := NULL;
                vsp    := 1;

               END;


--- obtenemos los valores del parametrizador para cada tipo de accesorio
        begin
            select ZSTPARA_PARAM_ID, ZSTPARA_PARAM_VALOR
                into v_code_etiq, v_code_dtl
               from zstpara
                where 1=1
                 and zstpara_mapa_id = 'code_cero'
                 and ZSTPARA_PARAM_DESC = pcode;
           exception when others then
           v_code_etiq  :='';
           v_code_dtl   :='';


         end;


-- primero validamos que ese alumno tenga su etiqueta en GORADID--TIIN-- hay que vincular con un poarametrizador code serv vs etiqueta vs code detalle
        begin
              select 'Y'
               into v_etiqueta
                from goradid
                 where 1=1
                  and goradid_pidm = ppidm
                  and GORADID_ADID_CODE = v_code_etiq;

        exception when others then
      v_etiqueta  :='N';


    end;
         ----dbms_output.put_line('salida etiqueta goradid  '||v_etiqueta||'-'|| v_code_etiq  );
-- segundo busco si existe un cargo con ese codigo de detalle del accesorio cero pesos
    begin


        --SELECT DISTINCT COUNT(t.TBRACCD_TRAN_NUMBER), MIN(t.TBRACCD_TRAN_NUMBER)  ajuste para que solo regrese 1 valor glovicx 29.05.2024
        SELECT DISTINCT MIN(t.TBRACCD_TRAN_NUMBER)
          into   v_no_trans
            FROM TBBDETC d , tbraccd t
              WHERE TBBDETC_DETAIL_CODE = T.TBRACCD_DETAIL_CODE
                and tbraccd_pidm = ppidm
                and   T.TBRACCD_DETAIL_CODE  = substr(F_GetSpridenID(ppidm),1,2)|| v_code_dtl --AQUI UN PARAMETRIZADOR EN LUGAR DE RK
                and   T.TBRACCD_STSP_KEY_SEQUENCE = vsp
                ;

    exception when others then
      v_no_trans  := 0;
      v_COUNT_trans := 0;
     -- dbms_output.put_line('error en tbracc  '||ppidm ||'-'|| vsp||'-'||  sqlerrm);
    end;

     --dbms_output.put_line('salida num trans tbra  '||v_COUNT_trans||'-'|| v_no_trans ||'-'||v_code_dtl||vsp );
            ---si campus es null es por que solo estoy consultando el precio y no debe de borra nada
            -- si campus es NOT NULL es por que ya estoy insertando el accesorio y entonces si debe de borrar OK
        If  v_etiqueta = 'Y' and v_no_trans >=1 and pcampus is not null then

        null;
        --si tiene etiqueta y tiene UNA caretera solo una cartera entonces le quitamos la etiqueta para
        ---  que la siguiente que pida ya le cueste dinero y se guarda en la bitacora de banner
            PKG_FREEMIUM.quita_etiqueta(ppidm, v_code_etiq);
            PKG_FREEMIUM.bitacora (ppidm, null, v_no_trans, pprograma, 'Se elimina la etiqueta '||v_code_etiq||' por que ya la ocupo '||pcode );

            --insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7, valor8)
            --values ('func_acc CAMP not NULL ',ppidm,pcode, pprograma ,v_etiqueta ,v_COUNT_trans,v_no_trans , vsp );

        else
        null;
               -- insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7, valor8)
            --values ('func_acc CAMP ISSS NULL ',ppidm,pcode, pprograma ,v_etiqueta ,v_COUNT_trans,v_no_trans , vsp );

        --manda se le tiene que cobrar el accesorio

        end if;



--insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7, valor8)
--values ('func_acc costo cero',ppidm,pcode, pprograma ,v_etiqueta ,v_COUNT_trans,v_no_trans , vsp );

RETURN (v_etiqueta||'|'||v_no_trans);


EXCEPTION WHEN OTHERS THEN
vl_error  := SQLERRM;

end F_accesorio_costo_cero;


FUNCTION F_MESES_COLF ( PPIDM NUMBER, PCODE  VARCHAR2, pprograma varchar2 )  Return  PKG_SERV_SIU.colf_dif_type
IS

  TYPE t_Cursor IS REF CURSOR;
--funcion para el proyecto de COLF  a plazos diferidos:
--GLOVICX 22/02/021
--- CAMBIOS A LA FUNCION PARA SERVICIO DE UNICEF Y DE CONECTA GLOVICX 21/01/022
-- SE LIBERA CAMBIO PARA LA FUNCIONALIDAD DE VOXY 14/04/022 GLOVICX

  cuCursor SYS_REFCURSOR;


  RetVal varchar2(32767);

  P_SP NUMBER;
  P_NIVEL VARCHAR2(32767);
  P_PERIODO VARCHAR2(32767);
  vnivel  varchar2(4);
  vsp     varchar2(1);
  vperiodo varchar2(8);
  VPOR_CC   NUMBER:=0;
  VPOR_CC2  NUMBER:=0;
  vjornada    number:=0;

  vmeses     varchar2(8);
  vcuenta    number:=0;
  vcampus     varchar2(4);
  vstatus    varchar2(4);




BEGIN
--------buscamos el pidm que campus debe ser -- para que presente los meses a diferir
      begin
         select distinct CAMPUS, ESTATUS
          into vcampus,vstatus
           from tztprog t
            where 1=1
            and pidm = ppidm
            and programa =  pprograma;

      exception when others then
        begin
          select distinct CAMPUS, ESTATUS
          into vcampus,vstatus
           from tztprog t
            where 1=1
            and pidm = ppidm
             and sp = (select max (sp)  from tztprog t2  where t.pidm = t2.pidm  and estatus = 'EG' );

         exception when others then
         vcampus := '';
         vstatus :='' ;
         end;

      end;
----dbms_output.put_line('al salir de estatus:  '|| vstatus );

     begin
       SELECT DISTINCT SORLCUR_LEVL_CODE, SORLCUR_APPL_KEY_SEQNO,SORLCUR_TERM_CODE
          INTO  vnivel, vsp, vperiodo
            FROM SORLCUR
            WHERE 1=1
            AND SORLCUR_PIDM = PPIDM
            AND SORLCUR_LMOD_CODE = 'LEARNER'
            and SORLCUR_CACT_CODE = 'ACTIVE'
            and SORLCUR_PROGRAM = pprograma;


     EXCEPTION WHEN OTHERS THEN


       vnivel       := NULL;
       vsp          := NULL;
       vperiodo     := NULL;
        vl_error := 'en sorlcur'|| sqlerrm;
        ----dbms_output.put_line('error en sorlcur'||vl_error);
     end;



  ---AQUI ME REGRESA LA JORNADA Y EL ÚLTIMO NUMERO ES EL NUMERO DE MATERIAS QUE LLEVA EL ALUMNO

        BEGIN

          P_SP := vsp;
          P_NIVEL := vnivel;
          P_PERIODO := vperiodo;

          RetVal := BANINST1.PKG_UTILERIAS.F_CALCULA_JORNADA ( PPIDM, P_SP, P_NIVEL, P_PERIODO );

          vjornada := substr(RetVal,4,1);

         -- --dbms_output.PUT_LINE('salida de jornada:  '||PPIDM||'->'|| RetVal||'--'|| vjornada);
          EXCEPTION WHEN OTHERS THEN
          RetVal  := 2;
           vl_error :=  'f_cal_jornada'||sqlerrm;
           ----dbms_output.put_line('error en F_jornada'||vl_error);
        END;


       BEGIN
        select distinct SZTHITA_X_CURSAR
          INTO VPOR_CC
                from SZTHITA
                where 1=1
                and SZTHITA_PIDM = PPIDM
                AND  SZTHITA_LEVL = P_NIVEL
                AND SZTHITA_STUDY  = P_SP;

        exception when others then
              begin

                    select distinct SZTHITA_X_CURSAR
               INTO VPOR_CC
                from SZTHITA
                where 1=1
                and SZTHITA_PIDM = PPIDM
                AND  SZTHITA_LEVL = P_NIVEL
                --AND SZTHITA_STUDY  = P_SP
                ;

               exception when others then

                VPOR_CC  := 0;
                vl_error :=  'szthita'||sqlerrm;
                ----dbms_output.put_line('error en thita'||vl_error||PPIDM||'-'||P_NIVEL||'-'|| P_SP );
               end;

        null;

       END;



IF PCODE in ( 'CNLI', 'CNMA' ,'CNMM','CNDO')  then
----AQUI ENTRA SI EL CODIGO ES DIFERENTE DE COLF---seccion para CONECTA

open cuCursor for select distinct  SUBSTR(F_GETSPRIDENID(Ppidm),1,2)|| SUBSTR(ZSTPARA_PARAM_DESC,1, INSTR(ZSTPARA_PARAM_DESC,',',1)-1 )  CODE,
                       -- DECODE(substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1),1,substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1)|| ' Mensual',6,substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1)||' Semestral')   || ' $ '|| ZSTPARA_PARAM_VALOR PAGOS
                       DECODE(substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1),1,' Mensual',6,' Semestral')  PAGOS
                        from ZSTPARA
                             where 1=1
                               AND ZSTPARA_MAPA_ID = 'COSTO_CONECTA'
                                AND substr(ZSTPARA_PARAM_ID,3,2) = vnivel;
                            --and  substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1) = pmeses


----dbms_output.put_line('salida dentro del curso conecta nivel '|| vnivel||'-'||  ppidm );

ELSIF PCODE in ( 'UNLI', 'UNMA' ,'UNMM')  then
--+++++++++++++++++- ESTA SECCION ES PARA UNICEF---
open cuCursor for SELECT DISTINCT z2.ZSTPARA_PARAM_VALOR||datos.num , DATOS.NUM||DATOS.MESES
FROM (
select distinct  ZSTPARA_PARAM_DESC cve_dtl,
                  TO_NUMBER(substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1  )) NUM
                   ,decode ( substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1  ),1,' UN PAGO ',' MESES '  )
                                   ||  '|||' ||substr(ZSTPARA_PARAM_VALOR, instr(ZSTPARA_PARAM_VALOR,',',1)+1)
                                      MESES
                        from ZSTPARA
                          where 1=1
                            and ZSTPARA_MAPA_ID = 'COST_UNICEF_1SS'
                            and substr(ZSTPARA_PARAM_DESC,1,2) = substr(F_GetSpridenID(ppidm),1,2)
                            and substr(ZSTPARA_PARAM_ID,instr(ZSTPARA_PARAM_ID,',',1)+1,5  ) = vnivel
                            ORDER BY 2
) DATOS,ZSTPARA z2
where 1=1
and z2.ZSTPARA_PARAM_ID = DATOS.cve_dtl
and z2.ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'
ORDER BY 1
;

ELSIF PCODE = 'VOXY' THEN
open cuCursor for  select datos.ZSTPARA_PARAM_VALOR codigo, datos.ZSTPARA_PARAM_DESC||'|'||substr(z2.ZSTPARA_PARAM_VALOR,instr(z2.ZSTPARA_PARAM_VALOR,',',1)+1,6) as nombre
                      from (
                            select z1.ZSTPARA_PARAM_VALOR, z1.ZSTPARA_PARAM_DESC
                            --INTO VMESES
                                from ZSTPARA z1
                                where 1=1
                                and z1.ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'
                                and z1.ZSTPARA_PARAM_DESC LIKE ('%VOXY%')
                                and substr(z1.ZSTPARA_PARAM_ID,1,2) =  substr(F_GetSpridenID(ppidm),1,2)
                                ) datos,  ZSTPARA z2
                            where 1=1
                            and  datos.ZSTPARA_PARAM_VALOR = z2.ZSTPARA_PARAM_DESC
                            and ZSTPARA_MAPA_ID ='COST_VOXY_1SS'
                            and substr(ZSTPARA_PARAM_ID,instr(ZSTPARA_PARAM_ID,',',1)+1,2)  = vnivel ;




ELSIF PCODE = 'COLF' AND  vcampus = 'UTL' and vstatus = 'EG' THEN

-- ESTA SECCION ES PARA COLF DIF
 ----dbms_output.put_line('alumno con estatus:  ' ||'-'||vstatus  );
----SI EL CAMPUS DEL ALUMNO ES UTL Y EGRESADO ENTONCES SOLO TIENE DE 2 A 6 MESES
open cuCursor for SELECT DATOS.NUMERO, DATOS.MESES
                    FROM (
                    SELECT 1 AS NUMERO, '1 MES' AS MESES
                    FROM DUAL
                    union
                    SELECT 2 AS NUMERO, '2 MESES' AS MESES
                    FROM DUAL
                    union
                    SELECT 3, '3 MESES'
                    FROM DUAL
                    union
                    SELECT 4, '4 MESES'
                    FROM DUAL
                    union
                    SELECT 5, '5 MESES'
                    FROM DUAL
                    union
                    SELECT 6, '6 MESES'
                    FROM DUAL
                    ) DATOS
                    ;
ELSIF  PCODE = 'COLF' AND vcampus = 'UTL' and vstatus != 'EG' THEN  -- ESTA OPCION ES PARA TODOS LOS QUE NO SON EG Y SE VAN A UN SOLO PAGO.
----dbms_output.put_line('alumno con estatus2:  ' ||'-'||vstatus  );
open cuCursor for SELECT DATOS.NUMERO, DATOS.MESES
                    FROM (
                    SELECT 1 AS NUMERO, '1 MES' AS MESES
                    FROM DUAL ) DATOS;


ELSIF PCODE = 'COLF' AND vcampus = 'UIN' and vstatus = 'MA'  THEN


--10 materias por cursa son entre la carga de materias 2 por bimestre = 5 bimestres
--5 bimestres = 10 meses

      ---el numero de materias por cursar se divide entre la carga de materias
      VPOR_CC2 := (VPOR_CC/vjornada)*2;

     -- --dbms_output.put_line('número de bimestre/meses:  '|| ppidm||'-'||VPOR_CC||'->'||vjornada||'->>'|| VPOR_CC2 );
       -- el resultado se multiplica por 2 que es la cantidad de meses por bimestre
    --  VPOR_CC2 := VPOR_CC2 * 2;
     --  --dbms_output.put_line('número de meses:  '|| VPOR_CC2 );


 --g_tb_spei.DELETE;
 begin
 delete saturn.stmeses
 where 1=1
 and  pidm = ppidm;

 exception when others then
 ----dbms_output.put_line('error al borrra la tabla principal  '|| ppidm );
  vl_error := 'borra tbl'|| sqlerrm;
 end;


for jump in 1..VPOR_CC2-1 loop

 if jump != 1 then
   vmeses  := ' MESES';
    -- --dbms_output.PUT_LINE('DENTRO DE MESES::: '|| vmeses );
   ELSE
   vmeses  := ' MES';
  -- --dbms_output.PUT_LINE('DENTRO DE MESSS:::  '|| vmeses );
   END IF;

                      --  g_tb_spei(jump).nmeses     := jump||vmeses;

         insert into saturn.stmeses(pidm,numerom, meses)  values  (ppidm, jump, jump||vmeses );

      vcuenta := vcuenta +1 ;
 ----dbms_output.put_line('regs tabla:  ' ||'-'||vcuenta  );
 end loop;


----dbms_output.put_line('alumno con estatus3:  ' ||'-'||vstatus  );
---   SI EL CAMPUES DEL ALUMNO ES DIFERENTE ES UN AFILIADO ENTONCES LE DA LOS MESES QUE SE LE CALCULARON POR NUMERO DE MESES QUE LE FALTAN
 open cuCursor for  select distinct numerom,meses
                              from saturn.stmeses
                              where 1=1
                               and pidm = ppidm
                               and rownum < 13
                               order by numerom;

ELSE
 open cuCursor for  SELECT 1 AS NUMERO, '1 MES' AS MESES
                    FROM DUAL;

END IF;

   NULL;

   return cuCursor;

   NULL;


  Exception
    When others  then
       vl_error :=  sqlerrm;
   --return cuCursor;
----dbms_output.put_line('error general '|| vl_error );
END F_MESES_COLF;


FUNCTION F_CANCELA_COLF_DIF  (PPIDM NUMBER, NO_SEQNO NUMBER, PCODE VARCHAR2  ) RETURN VARCHAR2 IS

--ESTA funcion es para hacer la cancelacion del servicio y la cancelacion de la cartera  COLF diferidos unicamente  glovicx 25/02/021
--se agrego la funcion de reza para cancelar la cartera glovicx 13/10/2021--
vsqlerr     varchar2(500):='EXITO';
VPROGRAMA   varchar2(14);
vstst       varchar2(4);
vlevel      varchar2(4);
vcamp       varchar2(4);
p_delivery_type  varchar2(4);
vimporte_envio     number:=0;
VDESC_DTL        varchar2(50);

BEGIN

    ----dbms_output.put_line('antes de cancel'||PPIDM||'-'||NO_SEQNO );

       begin

           vsqlerr :=  PKG_FINANZAS_REZA.F_CANCELA_DIFERIDO(PPIDM,NO_SEQNO );

        exception when otherS then
          vsqlerr  := sqlerrm;
        end;

    ----dbms_output.put_line('salida del proceso reza : '|| vsqlerr );
    --INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3 , VALOR4, valor5, valor6 )
      --VALUES('FUNCION CANCELA COLF DIFERIDA 2  ', PPIDM, NO_SEQNO , PCODE, vsqlerr,sysdate  );COMMIT;


  if vsqlerr = 'EXITO'  then


    ---se realizan las validaciones para saber si tiene envio internacional---

       BEGIN    -----------------recupera la parte de periodo que solicito el alumno
           select DISTINCT SVRSVAD_ADDL_DATA_CDE,SVRSVPR_WSSO_CODE
                INTO VPROGRAMA, p_delivery_type
                from svrsvpr v,SVRSVAD VA
                where SVRSVPR_SRVC_CODE = PCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = NO_SEQNO
                AND  SVRSVPR_PIDM    = PPIDM
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                and va.SVRSVAD_ADDL_DATA_SEQ = '1'---fechas inicio parte prd
          ;
       EXCEPTION WHEN OTHERS THEN
            VPROGRAMA:='';
            vsqlerr := sqlerrm;
             ----dbms_output.put_line(' error en programa   '|| vsqlerr  );
       END;
      ----dbms_output.put_line(' despues de  programa   '|| vsqlerr  );

      begin
        select SGBSTDN_STST_CODE, SGBSTDN_LEVL_CODE, SGBSTDN_CAMP_CODE
          into  vstst, vlevel, vcamp
        from sgbstdn  c
        where C.sgbstdn_PIDM  = PPIDM
        and  c.SGBSTDN_TERM_CODE_EFF = ( select max(SGBSTDN_TERM_CODE_EFF) from sgbstdn cc
                                            where Cc.sgbstdn_PIDM  = c.sgbstdn_PIDM
                                             and  CC.SGBSTDN_PROGRAM_1  = VPROGRAMA
                                         )  ;
      exception when others then
        null;

            ----dbms_output.put_line( 'ERRORR:::SALIDA GASTON ;'||vstst||'-'||vlevel||'-'|| vcamp );
      end;

      ----dbms_output.put_line(' error en gaston    '|| vsqlerr  );
      ------  aquie  hay que meter el cargo de costo del servicio de envio si es que existe--
     vimporte_envio :=  BANINST1.PKG_SERV_SIU.F_COSTO_ENVIO ( UPPER(PCODE),vstst,vcamp,vlevel, p_delivery_type   );

       BEGIN
          SELECT DISTINCT TBBDETC_DESC
           INTO    VDESC_DTL
           FROM TBBDETC
           WHERE TBBDETC_DETAIL_CODE = p_delivery_type;
     EXCEPTION WHEN OTHERS THEN
             --   VSALIDA:='Error :'||sqlerrm;
                 VDESC_DTL:='';

     END;


       ---vcodigo_dtl := p_delivery_type;


     ----dbms_output.PUT_LINE('EL IMPORTE DEL EVIOS ES > A0-- ANTES  CARTERA '|| vimporte_envio||'<<>>'|| vsqlerr||'--'||p_delivery_type||'-'|| VDESC_DTL);

    IF vimporte_envio > 0 THEN
     NULL;

     --aqui mandamos la cancelación
       vsqlerr :=   BANINST1.PKG_SERV_SIU.P_CAN_SERV_ALL (PCODE,PPIDM,NO_SEQNO,'CAN_COLF_DIFF'  );


     ----dbms_output.PUT_LINE('EL IMPORTE DEL EVIOS ES > A 0-- INSERTA CARTERA '|| vimporte_envio||'<<>>'|| vsqlerr );
    END IF;

    --se manda hasta el ultimo para que cancele el envio 12/11/021
         begin
         UPDATE  svrsvpr
                   SET SVRSVPR_SRVS_CODE     = 'CA',
                   SVRSVPR_INT_COMMENT       = 'CANCELACION POR EL USUARIO'
                where SVRSVPR_SRVC_CODE      = PCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = NO_SEQNO
                AND  SVRSVPR_PIDM            = PPIDM;

        exception when others then
        vsqlerr  :='ERROR AL ACTUALIZAR SVRSVPR' ;
        end;


        RETURN ('EXITO');

ELSE

RETURN (vsqlerr);

END IF;


 exception when others then
        vsqlerr  :='ERROR GENERAL CANCELA_COLF_DIF' ;


END F_CANCELA_COLF_DIF;

FUNCTION F_COLF_DIFF ( PPIDM NUMBER, PCODE_DTL VARCHAR2, PMESES NUMBER,PPROGRAMA VARCHAR2,PNO_SERV NUMBER , PCODE VARCHAR2,p_delivery_type VARCHAR2,
                       PTERM VARCHAR2,  f_inicio VARCHAR2, Pstudy VARCHAR2, Ppparte VARCHAR2, Pcode_curr  VARCHAR2,Pstst VARCHAR2,Pcamp VARCHAR2,Plevel VARCHAR2  )  RETURN VARCHAR2 IS

vcodigo_dtl   VARCHAR2(10); --CODIGO DEL ENVIO
VDESC_DTL     VARCHAR2(50); --DESCRIPCION DEL ENVIO
vsal_dif       VARCHAR2(50);
VSALIDA       VARCHAR2(200);
vsal_notran   VARCHAR2(5);
vimporte_envio    NUMBER:=0;
PFECHA_INI      varchar2(1); ---regla para este caso de COLF diferrida siempre va NULO
vfeed            varchar2(20);
BEGIN

    --  insert into twpasow( valor1, valor2, valor3, valor4, valor5)
    -- values( 'Dentro FUNCION F_COLF_DIFF',PPIDM, PNO_SERV,PFECHA_INI, SUBSTR(vsal_dif,1,600) );
   --  commit;
  -- --dbms_output.PUT_LINE('INICIO COLF DIFF'||PTERM||'-'||vimporte_envio||'-'||PNO_SERV||'-'||f_inicio||'-'||Pstudy||'-'||Ppparte||'-'||Pcode_curr);

    BEGIN
     vsal_dif :=  PKG_FINANZAS_REZA.F_ACC_DIFERIDO( PPIDM, PCODE_DTL, PMESES, PPROGRAMA,PNO_SERV, PFECHA_INI );
    EXCEPTION WHEN OTHERS THEN
    vsal_dif  := SQLERRM;
    -- insert into twpasow( valor1, valor2, valor3, valor4, valor5)
    -- values( 'Dentro ERROR FUNCION REZA',PPIDM, PNO_SERV,PFECHA_INI, SUBSTR(vsal_dif,1,600) );
    -- vsal_dif  := SQLERRM;
    END;


-- SE EJECUTA LA FUNCION DE Reza PARA CARGOS DIFERIDOS---


   -- --dbms_output.put_line(' salidaFUNCION REZA1:  '||vsal_dif);

   VSALIDA :=  substr(vsal_dif, 1,instr(vsal_dif,'|',1)-1);
   vsal_notran := substr( vsal_dif,instr(vsal_dif,'|',1)+1); --se obtiene la primer no_transaccion de los cargos diferidos que se insertan en la cartera

    --insert into twpasow( valor1, valor2, valor3, valor4, valor5)
     --values( 'Dentro f_colf_diff desp funcion REZA',PPIDM, PNO_SERV,VSALIDA, SUBSTR(vsal_dif,1,100) );
    --commit;


   IF VSALIDA = 'EXITO' and Pcamp = 'UTL'  THEN
   ----dbms_output.put_line(' salidaFUNCION REZA2:  '||VSALIDA||'-'||vsal_notran);
   begin
         UPDATE  svrsvpr
               SET SVRSVPR_SRVS_CODE         = 'PR',
               SVRSVPR_STEP_COMMENT           = 'DIFERIDA', --PARA IDENTIFICAR UNA COLF NORMAL Y DIFERIDA
               SVRSVPR_ACCD_TRAN_NUMBER      = vsal_notran
                where SVRSVPR_SRVC_CODE      = PCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                AND  SVRSVPR_PIDM            = PPIDM;
     exception when others then
     null;
      end;

      ------  aquie  hay que meter el cargo de costo del servicio de envio si es que existe--
     vimporte_envio :=  BANINST1.PKG_SERV_SIU.F_COSTO_ENVIO ( UPPER(PCODE),Pstst,Pcamp,Plevel, p_delivery_type   );

   elsif VSALIDA = 'EXITO' and Pcamp = 'UIN'  THEN

      begin
         UPDATE  svrsvpr
               SET SVRSVPR_SRVS_CODE         = 'CL',
               SVRSVPR_STEP_COMMENT           = 'DIFERIDA', --PARA IDENTIFICAR UNA COLF NORMAL Y DIFERIDA
               SVRSVPR_ACCD_TRAN_NUMBER      = vsal_notran
                where SVRSVPR_SRVC_CODE      = PCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                AND  SVRSVPR_PIDM            = PPIDM;
       exception when others then
       null;
      end;

   END IF;

    BEGIN
          SELECT DISTINCT TBBDETC_DESC
           INTO    VDESC_DTL
           FROM TBBDETC
           WHERE TBBDETC_DETAIL_CODE = p_delivery_type;
     EXCEPTION WHEN OTHERS THEN
             --   VSALIDA:='Error :'||sqlerrm;
                 VDESC_DTL:='';

     END;


       vcodigo_dtl := p_delivery_type;


  ----dbms_output.PUT_LINE('EL IMPORTE DEL EVIOS ES > A0-- ANTES  CARTERA '|| vimporte_envio||'<<>>'|| VSALIDA||'--'||Vcodigo_dtl||'-'|| VDESC_DTL);

    IF vimporte_envio > 0 THEN
     NULL;

     --AQUI MANDAMOSNUEVA FUNCION PARA INSERTAR TBRACCD SOLO EL ENVIO  GLOVICX COLF DIF,  08/04/021
       VSALIDA :=   BANINST1.PKG_SERV_SIU.F_INSERT_CARTERA (PCODE,PPIDM,PTERM,Vcodigo_dtl,vimporte_envio,VDESC_DTL,PNO_SERV,'COLFDIF', f_inicio,Pstudy,Ppparte,Pcode_curr,vfeed,null);

     ----dbms_output.PUT_LINE('EL IMPORTE DEL EVIOS ES > A 0-- INSERTA CARTERA '|| vimporte_envio||'<<>>'|| VSALIDA );
    END IF;

     --insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6,valor7,valor8,valor9,valor10,valor11,valor12,valor13   )
     --values( 'Dentro f_colf_diff desp inserta tbraccd envio > 0:  ',PCODE, PPIDM,VSALIDA, PTERM,Vcodigo_dtl,vimporte_envio,VDESC_DTL,PNO_SERV, f_inicio,Pstudy,Ppparte,Pcode_curr );
    --commit;

         IF  instr(VSALIDA,'|',1) > 1  THEN  -- POR SI PASA POR EL COSTO DE ENVIO LE QUITE EL PIPE GLOVICX 26/10/021
                VSALIDA :=  substr(VSALIDA, 1,instr(VSALIDA,'|',1)-1);
        END IF;






  IF VSALIDA = 'EXITO' THEN
        COMMIT;
        RETURN (VSALIDA);
   ELSE
          ROLLBACK;
       RETURN (VSALIDA);
  end if;




EXCEPTION WHEN OTHERS THEN
null;
RETURN (VSALIDA);
----dbms_output.PUT_LINE('ERROR GRAL F_COLF_DIFF'|| VSALIDA );

END F_COLF_DIFF;

FUNCTION F_VALIDA_SALDO_COLF  (  PPIDM  NUMBER, pcampus varchar2, pseqno number )  RETURN VARCHAR2 IS


--ppidm      number:=0;
vpseq_no   number:=0;
vsum_balance   number:=0;
VERROR      VARCHAR2(500);
vcode      varchar2(5);
vsalida     varchar2(25):= 'EXITO';
-- esta nueva funcion para regresar el saldo que vaya teniendo una COLF- Diferida se va utilizar en el dashboard de pagos para la COLF Diferida unicamente
--  te va calculando cuando es el saldo y al final si ya esta en ceros pasa el accesorio a pagado  glovicx. 18/06/2021
BEGIN

---sacamos el codigo
       begin
            select distinct ZSTPARA_PARAM_ID
              into vcode
            from zstpara
             where 1=1
              and ZSTPARA_MAPA_ID  = 'TITULA_DIFERIDA'
              and ZSTPARA_PARAM_VALOR  = pcampus;
        EXCEPTION WHEN OTHERS THEN
          Vcode := null;
          vsalida := 'No es Diferido';
          ----dbms_output.PUT_LINE('error en codigo '||Vcode ||'-'||vsalida);
        end;


---primero calculamos si tiene colf para obtener el No_seq.
      BEGIN
        select nvl(MAX(SVRSVPR_PROTOCOL_SEQ_NO), 0)
           into vpseq_no
        from SVRSVPR  v
        WHERE 1=1
        and   v.SVRSVPR_PIDM = PPIDM
        and  v.SVRSVPR_SRVS_CODE IN ('PR', 'CL')---NOT IN ('AC','PA')
        and  V.SVRSVPR_SRVC_CODE  = vcode
        and  v.SVRSVPR_PROTOCOL_SEQ_NO   = pseqno;

       EXCEPTION WHEN OTHERS THEN
       vpseq_no := 0;
       vsalida := 'No es Diferido';
       ----dbms_output.PUT_LINE('error en SEQNO  '||vcode ||'-'||vsalida);
       END;

  ----dbms_output.PUT_LINE('RECUPERA NUMACCESORIO: '||vpseq_no ||'-'||vsalida);
 if vpseq_no = 0 then
     vsalida := 'No es Diferido';
  else
------SEGUNDO SUMAMOS EL SALDO
      BEGIN
       select NVL(sum(TBRACCD_BALANCE),0)
          INTO vsum_balance
        from tbraccd tt
        where 1=1
        and tt.tbraccd_pidm = PPIDM
        and  TT.TBRACCD_CROSSREF_NUMBER = vpseq_no
        and TT.TBRACCD_DETAIL_CODE in (select ZSTPARA_PARAM_VALOR MAIL
                                        from zstpara
                                        WHERE 1=1
                                        AND  ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'  )
        and tt.TBRACCD_TRAN_NUMBER = ( select min (TBRACCD_TRAN_NUMBER) from tbraccd tt2
                                where 1=1
                                  and ( TBRACCD_AMOUNT = TBRACCD_BALANCE
                                      OR TBRACCD_BALANCE > 0 )
                                   and tt.tbraccd_pidm     = tt2.tbraccd_pidm
                                    and  TT.TBRACCD_CROSSREF_NUMBER = TT2.TBRACCD_CROSSREF_NUMBER
                                    and TT.TBRACCD_DETAIL_CODE in (select ZSTPARA_PARAM_VALOR MAIL
                                                                        from zstpara
                                                                        WHERE 1=1
                                                                        AND  ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'  ));



       EXCEPTION WHEN OTHERS THEN
       vsum_balance := NULL;
       vsalida := 'No es Diferido';
        ----dbms_output.PUT_LINE('error en balance: '||vpseq_no ||'-'||vsalida);
       END;
  end if;


----dbms_output.PUT_LINE('RECUPERA SALDO: '||vsum_balance||'-'|| vsalida );

IF vsum_balance = 0 then
--   hace la actualizacion a PA

                UPDATE  svrsvpr
                   SET SVRSVPR_SRVS_CODE     = 'PA',
                   SVRSVPR_INT_COMMENT       = 'SALDO EN CEROS COLF DIFERIDA',
                   SVRSVPR_ACTIVITY_DATE     = SYSDATE
                where SVRSVPR_SRVC_CODE      = vcode
                AND  SVRSVPR_PROTOCOL_SEQ_NO = vpseq_no
                AND  SVRSVPR_PIDM            = PPIDM;


  ----dbms_output.PUT_LINE('dentro del balance update: '||vpseq_no ||'-'||vsalida);
-- RETURN(vsum_balance);

else
----dbms_output.PUT_LINE('dentro del balance >  cero  '|| vpseq_no ||'-'||vsum_balance);
-- solo regresa el saldo pendiente de esa transación
null;

end if;

RETURN to_char( vsum_balance );



EXCEPTION WHEN OTHERS THEN
      RETURN ('ERROR F_VALIDA_SALDO_COLF: '||VERROR );

end F_VALIDA_SALDO_COLF;

FUNCTION F_CODE_SIU   ( PPIDM NUMBER, PSEQNO  NUMBER) RETURN VARCHAR2  IS
--ESTA FUNCION LA PIDIO ANGEL PARA IDENTIFICAR EL ACCESORIOS DE COLF- DIFERIDA SE DEBE DE LIBERAR CUANDO SALGA ESE PROYECTO
--ESTA FUNCION REGRESA SI ES COLF_DIFERIDA
--
-- GLOVICX 21/09/021

v_srvc_code  varchar2(4):='NA';


begin
        select  DISTINCT V.SVRSVPR_SRVC_CODE
            into   v_srvc_code
        from SVRSVPR  v
        WHERE 1=1
        and   v.SVRSVPR_PIDM = PPIDM
        and   V.SVRSVPR_PROTOCOL_SEQ_NO  = PSEQNO
        AND   V.SVRSVPR_STEP_COMMENT      = 'DIFERIDA';


RETURN( v_srvc_code );


EXCEPTION WHEN OTHERS THEN
vl_error  := SQLERRM;
RETURN ( 'NO HAY COINCIDENCIAS'  );

END F_CODE_SIU;



FUNCTION F_CESA (PPIDM NUMBER,PCODE_DTL VARCHAR2,  PPROGRAMA  VARCHAR2, PNO_SERV NUMBER, PCODE VARCHAR2  ) RETURN VARCHAR2
IS
-- ESTA FUNCION ES PARA EL ACCESORIO CESA QUE REZA SE ENCARGA DE INSERTAR LA CARTEA, TODO LO DE CESA VA AQUI-- GLOVICX 12/04/021
-- es una regla que siempre que se compre del autoservicio seran 18 meses el pago diferido, es una regla de negocio que dio el usuario.
-- nueva regla de susy de la fecha inicio se le restan 5 dias y ya no se permite que hagan la compra glovicx 26/07/2021

vsal_dif    VARCHAR2(6000):='EXITO|1';
VMESES      NUMBER:= 18;
VSALIDA     VARCHAR2(200):= 'EXITO';
vsal_notran  NUMBER:=1;
------
  RetVal        Varchar2(327);
  P_ADID_CODE   VARCHAR2(5):= 'CESA';
  P_ADID_ID         VARCHAR2(5):= 'CESA';
  vfECHA_INICIO     VARCHAR2(15);
 -- VFECHA_INICIO2   date;
  PFECHA_INI     VARCHAR2(15);
  Vpparte        varchar2(14);

vprograma       VARCHAR2(15);
vnivel          VARCHAR2(4);
vcampus         VARCHAR2(4);
vvalida_ups     VARCHAR2(60);
VBACK_PRONO     VARCHAR2(60);
l_regla         NUMBER:=0;
vetiqueta       VARCHAR2(60);

BEGIN

--insert into twpasow( valor1, valor2, valor3, valor4)
--        values( 'Dentro F_cesa1-1',PPIDM, PPROGRAMA, VSALIDA  );
--   commit;
--------------------------------estos parametros ya no los calculo por que este query ya lo calcula REZA dentro de su funcion-- 14/05/2021

        BEGIN    -----------------recupera la parte de periodo que solicito el alumno
              select substr(rango,1, instr(rango,'-AL-',1 )-1) as fecha_ini
                     INTO VFECHA_INICIO
                from (
                select
                      SVRSVAD_ADDL_DATA_DESC  rango
                         from svrsvpr v,SVRSVAD VA
                            where SVRSVPR_SRVC_CODE = pcode
                            AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                              AND  SVRSVPR_PIDM    = ppidm
                               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                               and va.SVRSVAD_ADDL_DATA_SEQ = '7' --- ES EL MISMO DEL PARTE DE PERIODO
                               ) ;


          EXCEPTION WHEN OTHERS THEN
            VFECHA_INICIO:=NULL;
--             insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7)
--           values( 'Dentro error F_cesa1-fecha INI',PPIDM, PCODE_DTL,VFECHA_INICIO ,PCODE,PNO_SERV, VSALIDA  );

          END;

            begin

                 select distinct t.programa,t.nivel, t.campus
                   INTO vprograma , vnivel, vcampus
                 from tztprog t
                  where 1=1
                  and  t.pidm = PPIDM
                  and t.sp = ( select max(t2.sp) from tztprog t2
                               where 1=1
                                and t2.pidm = t.pidm);


                ----dbms_output.PUT_LINE('despues de nivel SEJM:'||vprograma||'-'||  vnivel );
                EXCEPTION WHEN OTHERS THEN

                begin
                   select distinct SORLCUR_PROGRAM, SORLCUR_LEVL_CODE, SORLCUR_CAMP_CODE
                      INTO vprograma , vnivel, vcampus
                    from sorlcur s1
                   where 1=1
                   and sorlcur_pidm = PPIDM
                   and SORLCUR_SEQNO = (select max (SORLCUR_SEQNO)  from sorlcur s2
                                            where 1=1
                                              and s1.sorlcur_pidm = s2.sorlcur_pidm  );


                  EXCEPTION WHEN OTHERS THEN
                    vprograma := NULL;
                    vnivel    := null;
                    vcampus   := null;

                  end;


               END;



   IF  PCODE IN ('CELI','CEMA','CEMM')  THEN  --AQUI SIEMPRE ENTRA AFUERZAS

           --TO_CHAR(TO_DATE(SUBSTR(VL_VENCIMIENTO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY')

         BEGIN
             vvalida_ups := pkg_algoritmo_pidm.f_valida_ups(VFECHA_INICIO, PPIDM,vcampus,vnivel  );

         EXCEPTION WHEN OTHERS THEN
           VSALIDA  := vvalida_ups;
         END;
--                     insert into twpasow( valor1, valor2, valor3, valor4, VALOR5)
--                    values( 'salida fun chuy pkg_algoritmo_pidm(S/P) ',PPIDM, PPROGRAMA,vvalida_ups,  VSALIDA  ); commit;

         IF vvalida_ups = 'S'  THEN


             null; -- no hace nada
              VSALIDA:='EXITO';

         ELSIF vvalida_ups = 'P'  THEN
               --ESCENARIO 3 PARA LA FUNCION = P
               -- POR REGLA DE CHUY SOLO SE EJECUTA LA FUNCION DE

               vetiqueta:= PKG_RESA.inserta_etiqueta(PPIDM , p_adid_code , p_adid_id   );


               VBACK_PRONO :=  BANINST1.pkg_algoritmo_pidm.f_up_selling(TO_DATE(VFECHA_INICIO,'DD/MM/YYYY'),vprograma,PPIDM,vnivel )  ;
                VSALIDA:= VBACK_PRONO;
                    vetiqueta:= PKG_RESA.inserta_etiqueta(PPIDM , p_adid_code , p_adid_id   );

--            insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7)
--           values( 'Salida funcion chuy pkg_algotitmo= P',PPIDM, PCODE_DTL,VFECHA_INICIO ,vvalida_ups,vetiqueta, VSALIDA  ); commit;

         ELSE


                  ----dbms_output.PUT_LINE('ANTES DE IS PARA CEMA:  '||PNO_SERV||'-'||  PCODE );

--                  insert into twpasow( valor1, valor2, valor3, valor4, VALOR5, valor6)
--                    values( 'antes en calcula REGLA ',PPIDM, VFECHA_INICIO,vnivel,  vcampus ,vsalida  ); commit;

                   begin

                       select DISTINCT sztalgo_no_regla
                       into l_regla
                       from sztalgo
                       where 1 = 1
                       and SZTALGO_FECHA_NEW = to_date(VFECHA_INICIO,'DD/MM/YYYY') --VFECHA_INICIO
                       and sztalgo_camp_code =  Vcampus
                       and SZTALGO_LEVL_CODE = Vnivel;

                   exception when others then
                      vsalida := sqlerrm;
                       l_regla := 0;
--                       insert into twpasow( valor1, valor2, valor3, valor4, VALOR5, valor6)
--                        values( 'error en calcula REGLA ',PPIDM, VFECHA_INICIO,vnivel,  vcampus ,vsalida  ); commit;
                   end;





                   -- insert into twpasow ( valor1, valor2, valor3, VALOR4,VALOR5, VALOR21)
                    --    values('upselling_antes de funciones',VPIDM||'-'||Pserv||'--> '||VFINICIO2, vprograma, vnivel, l_regla,VFINICIO2  );
               --  COMMIT;

              ----dbms_output.PUT_LINE('antes de envio de funciones CEMA:  '||PPIDM||'-'||PNO_SERV||'--> '||VFECHA_INICIO ||'-'|| vprograma||'-'|| vnivel);


              VBACK_PRONO :=  BANINST1.pkg_algoritmo_pidm.f_up_selling(TO_DATE(VFECHA_INICIO,'DD/MM/YYYY'),vprograma,PPIDM,vnivel )  ;

--              insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7)
--              values( 'Salida funcion chuy pkg_algotitmo,f_up_selling NO ES ni S ni P',PPIDM, PCODE_DTL,VFECHA_INICIO ,vvalida_ups,l_regla, VBACK_PRONO  ); commit;



                    vetiqueta:= PKG_RESA.inserta_etiqueta(PPIDM , p_adid_code , p_adid_id   );

--                     insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7)
--                    values( 'Salida si todo es ok inserta etiqueta 1' ,PPIDM, PCODE_DTL,VFECHA_INICIO ,vetiqueta,PNO_SERV, VSALIDA  ); commit;


                   -----este procedimiento de p_ejecutivo_pidm hace el insert a sztalol  y necesita que ya este la etiqueta GORADID para que se ejecute de forma correcta regla la dio chuy junta 08/06/2021
               IF VBACK_PRONO = 'EXITO' THEN
                 BANINST1.pkg_algoritmo_pidm.p_ejecutivo_pidm(l_regla,PPIDM);
                 COMMIT;

               END IF;



             -- insert into twpasow ( valor1, valor2, valor3, VALOR4, VALOR5)
            --     values('upselling',VPIDM||'-'||Pserv||'--> '||VFINICIO ,  'EXEC_P_REZA-->'||VBACK_FINAN,'EXEC_P_CHUY-->'||VBACK_PRONO , SYSDATE  );
              --  COMMIT;


         --  --dbms_output.PUT_LINE('DESPUES  DE IS PARA SEJM'||  VCODE ||'-'|| VBACK_FINAN|| ' prono-->'|| VBACK_PRONO);
                   IF    VBACK_PRONO != 'EXITO' THEN

                   ----  SI ALGUNO DE LOS PROCESOS EXTRAS DE CHUY O REZA TRUENAN O SON DIF DE EXITO SE CANCELA LA SOLICITUD.
                      UPDATE  SVRSVPR  v
                       SET SVRSVPR_SRVS_CODE = 'CA'
                        WHERE 1=1
                        and   SVRSVPR_PIDM = PPIDM
                        AND   SVRSVPR_PROTOCOL_SEQ_NO =  PNO_SERV;

                      --   insert into twpasow ( valor1, valor2, valor3, VALOR4, VALOR5)
                       --   values('upselling_CANCELA',VPIDM||'-'||Pserv,  'EXEC_P_REZA'||VBACK_FINAN,'EXEC_P_REZA'||PDL_DATA_SEQ , SYSDATE  );

                   VSALIDA  := 'ERROR';---SE MANDA EL ERROR
                   else
                      VSALIDA  := 'EXITO'; ------terminaron con exito los procesos se inserta la eqitqueta en goradit
                      --verror := sqlerrm;
                    --   insert into twpasow ( valor1, valor2, valor3, VALOR4, VALOR5, valor6, valor7)
                     --      values('upselling_EXITOSO TODO OK ',VPIDM||'-'||Pserv,  'EXEC_P_REZA'||VBACK_FINAN,'EXEC_P_chuy'||VBACK_PRONO , TO_CHAR(TO_DATE(SUBSTR(VFINICIO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY'), verror,vetiqueta  );
                        ----------COMO TO YA FUE EXITO ENTONCES

                   END IF;




               VSALIDA:='EXITO';

         END IF;----INICIAL DE LA VALIDACION S/N/P


   END IF ; --GENERAL


----dbms_output.put_line('antes  funcion REXA '||VFECHA_INICIO  );
-- insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7)
--        values( 'Dentro F_cesa1-A',PPIDM, PCODE_DTL,VFECHA_INICIO ,PCODE,PNO_SERV, VSALIDA  );


  IF VSALIDA  ='EXITO'  THEN

            BEGIN
            vsal_dif :=  PKG_FINANZAS_REZA.F_ACC_DIFERIDO( PPIDM, PCODE_DTL, VMESES, PPROGRAMA,PNO_SERV, PCODE );
            EXCEPTION WHEN OTHERS THEN
            vsal_dif  := SQLERRM;
--             insert into twpasow( valor1, valor2, valor3, valor4, valor5)
--             values( 'Dentro ERROR FUNCION REZA',PPIDM, PNO_SERV,VFECHA_INICIO, SUBSTR(vsal_dif,1,600) );
            -- vsal_dif  := SQLERRM;
            END;

           VSALIDA :=  substr(vsal_dif, 1,instr(vsal_dif,'|',1)-1);

--           insert into twpasow( valor1, valor2, valor3, valor4, valor5, valor6, valor7)
--           values( 'Dentro F_cesa1-AAA desp function REZA',PPIDM, PCODE_DTL,VFECHA_INICIO ,PCODE,vsal_dif, VSALIDA  );



           IF VSALIDA = 'EXITO' THEN
           vsal_notran := substr( vsal_dif,instr(vsal_dif,'|',1)+1); --se obtiene la primer no_transaccion de los cargos diferidos que se insertan en la cartera

           else
           ---------por alguna razon trono la funcion de reza entonces se cancela la solictud
                begin
                     UPDATE  svrsvpr
                           SET SVRSVPR_SRVS_CODE         = 'CA',
                           SVRSVPR_INT_COMMENT           = 'cancelado',
                           SVRSVPR_ACCD_TRAN_NUMBER      = 0
                            where SVRSVPR_SRVC_CODE      = PCODE
                            AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                            AND  SVRSVPR_PIDM            = PPIDM;
                 exception when others then
                 null;
                 ----dbms_output.put_line('error en update svrsvpr'|| PPIDM||'-'|| PNO_SERV||'-'||PCODE||'-'||vsal_notran );
                  end;

           VSALIDA :='error funcion F_ACC_DIFERIDO ';

           END IF;

           ----dbms_output.put_line('salida despues funcion REXA '||vsal_dif  );
            --insert into twpasow( valor1, valor2, valor3, valor4, valor5)
             --values( 'Dentro F_cesa2',PPIDM, vsal_dif,VFECHA_INICIO, VSALIDA  );

                begin
                        select distinct  TO_CHAR(MAX(t.FECHA_INICIO), 'DD/MM/YYYY')
                             INTO PFECHA_INI
                            from tztprog t
                            where 1=1
                            and t.pidm = ppidm
                            and t.programa = PPROGRAMA    ;

                  EXCEPTION WHEN OTHERS  THEN
                    VFECHA_INICIO:= NULL;
                    VSALIDA  := SQLERRM;
                    ----dbms_output.put_line('error en tztprog'|| VFECHA_INICIO  );
                   END;

           --insert into twpasow( valor1, valor2, valor3, valor4, valor5)
             --   values( 'Dentro F_cesa3',PPIDM, PPROGRAMA,VFECHA_INICIO, VSALIDA  );
   END IF;

   IF VSALIDA = 'EXITO' THEN
   ----dbms_output.put_line(' salida F_CESA_ FUNCION REZA:  '||VSALIDA||'-'||vsal_notran);
       begin
             UPDATE  svrsvpr
                   SET SVRSVPR_SRVS_CODE         = 'CL',
                   SVRSVPR_INT_COMMENT           = 'concluido',
                   SVRSVPR_ACCD_TRAN_NUMBER      = vsal_notran
                    where SVRSVPR_SRVC_CODE      = PCODE
                    AND  SVRSVPR_PROTOCOL_SEQ_NO = PNO_SERV
                    AND  SVRSVPR_PIDM            = PPIDM;
         exception when others then
         null;
         ----dbms_output.put_line('error en update svrsvpr'|| PPIDM||'-'|| PNO_SERV||'-'||PCODE||'-'||vsal_notran );
          end;

   -----   MANDA A INSERTAR LA ETIQUETA EN GORADID CON LA FUNCION.-- NUEVA REGLA 23/04/2021 SUSY
      --insert into twpasow( valor1, valor2, valor3, valor4)
        --values( 'Dentro F_cesa2--A',PPIDM, PPROGRAMA, VSALIDA  ); commit;


        IF vvalida_ups = 'S'  THEN ----SE VALIDA ESTE PROCESO YA QUE SI ENTRA EN S NO HACE NADA DE CHUY PERO SI LO DE REZA E INSERTA LA ETIQUETA. GLOVICX 04/06/021
               BEGIN

                  P_ADID_CODE := 'CESA';
                  P_ADID_ID := 'CESA';

                  RetVal := BANINST1.PKG_RESA.INSERTA_ETIQUETA ( PPIDM, P_ADID_CODE, P_ADID_ID );

                              --insert into twpasow( valor1, valor2, valor3, valor4, VALOR5)
                              --values( 'Dentro F_cesa3--A',PPIDM, PPROGRAMA,RetVal,  VSALIDA  ); commit;

                VSALIDA := upper(SUBSTR(RetVal,1,5));

                   --insert into twpasow( valor1, valor2, valor3, valor4, VALOR5)
                    --values( 'Dentro F_cesa4--C',PPIDM, PPROGRAMA,RetVal,  VSALIDA  ); commit;

                 EXCEPTION WHEN OTHERS THEN
                  ----dbms_output.PUT_LINE('ERROR AL INSERTAR LA ETIQUETA: ');
                  --insert into twpasow( valor1, valor2, valor3, valor4, VALOR5)
                    --values( 'ERROR ETIQUEAT 2 F_cesaXX',PPIDM, PPROGRAMA,RetVal,  VSALIDA  ); commit;
                    null;

                END;
        END IF;




--      IF  UPPER(VSALIDA)  = 'EXITO' THEN
--         ---AQUI VA LA FUNCION PARA INSERTAR EN TZALOL  GLOVICX 23/04/021--
--         VSALIDA :=  PKG_SERV_SIU.F_INST_TZLOL (  PPIDM , PPROGRAMA , PFECHA_INI ,VFECHA_INICIO, 'F_CESA'  );
--      END IF;
--

      --insert into twpasow( valor1, valor2, valor3, valor4)
        --values( 'Dentro F_cesa4 ULTIMA',PPIDM, PFECHA_INI||'-'||VFECHA_INICIO, VSALIDA  ); commit;

   END IF;


Return (VSALIDA);

 Exception When others  then

        vl_error:='Error :'||sqlerrm;
        ----dbms_output.PUT_LINE('ERROOR EN F_CESA:.  ' || vl_error );
 Return (vl_error);

END F_CESA ;


FUNCTION F_INST_TZLOL (  PPIDM NUMBER, PPROGRAMA VARCHAR2, PFECHA_COMPRA VARCHAR2,PFECHA_INICIO VARCHAR2, PUSUARIO VARCHAR2) RETURN VARCHAR2
IS
---ESTA FUNCION SE HIZO PARA EL PROYECTO DE CESA SE HIZO POR FUERA POR QUE LA UTILIZA LA FUNCIO CESA PERO TAMBIEN ANGEL DESDE LA VENTA POR SEPARADO
-- ESTO LO MANDO FER 24/04/21  GLOVICX
verror  varchar2(200);


BEGIN




INSERT INTO SZTALOL
(SZTALOL_PIDM,
SZTALOL_ID,
SZTALOL_PROGRAMA,
SZTALOL_FECHA_COMPRA,
SZTALOL_FECHA_INICIO,
SZTALOL_NO_REGLA,
SZTALOL_FECHA_INSERTO,
SZTALOL_USUARIO,
SZTALOL_ESTATUS  )
VALUES (
PPIDM, --SZTALOL_PIDM,
F_GetSpridenID(PPIDM), --SZTALOL_ID,
PPROGRAMA, --SZTALOL_PROGRAMA,
to_date(PFECHA_COMPRA,'DD/MM/YYYY'), --SZTALOL_FECHA_COMPRA,
to_date(PFECHA_INICIO,'DD/MM/YYYY'), --SZTALOL_FECHA_INICIO,
null, --SZTALOL_NO_REGLA,
sysdate, --SZTALOL_FECHA_INSERTO,
PUSUARIO, --SZTALOL_USUARIO,
'A' --SZTALOL_ESTATUS
  );

Return('EXITO');


exception when others then
null;
verror  := sqlerrm;

----dbms_output.PUT_LINE('ERROR GRAL F_INST_TZLOL'|| verror );
Return(verror);


END  F_INST_TZLOL;



FUNCTION F_MESES_COLI ( PPIDM NUMBER, PCODE  VARCHAR2, PPROGRAMA  VARCHAR2 )  Return  varchar2
IS

--GLOVICX 24/09/021  funcion que devuelve el precio para saber escoger 1 oago o 12 pagos
-----proyecto CURSERA---
 -- cuCursor pkG_SERV_SIU.coli_type;
 -- ultimo ajuste 17/05/022 con las columnas del codigo de dtlle   padre.


  vnivel    varchar2(4);
  vcampus   varchar2(4);
  vsalida   varchar2(500):= 'EXITO';
  vetiqueta varchar2(50);


BEGIN

      begin

       DELETE SATURN.SZT_MESES_CURSERA2
         WHERE 1=1
         AND PIDM = PPIDM;

      exception when others then
         NULL;

       end;

      begin
         select distinct CAMPUS, nivel
          into vcampus,vnivel
           from tztprog t
            where 1=1
            and pidm = ppidm
            and programa = pprograma
            and sp = (select max (sp)  from tztprog t2  where t.pidm = t2.pidm and t2.programa = pprograma);

      exception when others then
        begin
          select distinct CAMPUS, nivel
          into vcampus,vnivel
           from tztprog t
            where 1=1
            and pidm = ppidm
            and programa = pprograma
             --and sp = (select max (sp)  from tztprog t2  where t.pidm = t2.pidm  and programa = pprograma )
             ;

         exception when others then
         vcampus := '';
         vnivel :='' ;
         vsalida  := 'ERROR EN TZTPROG:  '||SQLERRM;
         end;

      end;
----dbms_output.put_line('al salir de estatus:  '|| vnivel );


----la regla es para el combo del autoservicio y la cartera se toma la columna, ZSTPARA_PARAM_ID que trae el valor de
--- codigo de detll PADRE, refla de Gibran 17/05/022
 for jump in (
SELECT DISTINCT z2.ZSTPARA_PARAM_VALOR cve_dtl, DATOS.NUM||DATOS.MESES as meses, datos.precio,DATOS.NUM numbe
FROM (
select distinct  ZSTPARA_PARAM_DESC cve_dtl,
                  TO_NUMBER(substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1  )) NUM
                   ,decode ( substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1  ),1,' UN PAGO ',' MESES '  )
                                   ||  '|||' ||substr(ZSTPARA_PARAM_VALOR, instr(ZSTPARA_PARAM_VALOR,',',1)+1)
                                      MESES
                      ,substr(ZSTPARA_PARAM_VALOR,instr(ZSTPARA_PARAM_VALOR,',',1)+1,5 )  precio
                        from ZSTPARA
                          where 1=1
                            and ZSTPARA_MAPA_ID = 'COSTOS_COURSERA'
                            and substr(ZSTPARA_PARAM_DESC,1,2) = substr(F_GetSpridenID(PPIDM),1,2)
                            and substr(ZSTPARA_PARAM_ID,instr(ZSTPARA_PARAM_ID,',',1)+1,5  ) = vnivel
                            ORDER BY 2
) DATOS,ZSTPARA z2
where 1=1
and z2.ZSTPARA_PARAM_ID = DATOS.cve_dtl
and z2.ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'
ORDER BY 1  ) loop



 IF  jump.numbe = 1  then
 vetiqueta := 'UN PAGO';
 ELSE
 vetiqueta := jump.numbe||' MESES';
 END IF;



        begin

            insert into SATURN.SZT_MESES_CURSERA2(PIDM,MESES,PRECIO,CVE_DTL,DESCR)
              values ( PPIDM,jump.numbe, jump.precio, jump.cve_dtl, vetiqueta  );

        exception when others then
         vsalida  := 'ERROR EN INSRT CURSERA2'||SQLERRM;
         ----dbms_output.put_line('error en insert SZT_MESES_CURSERA2');
         end;


end loop;

 return vsalida ;

  Exception
    When others  then
       vsalida :=  sqlerrm;

----dbms_output.put_line('error general '|| vsalida );
return vsalida;

END F_MESES_COLI;


FUNCTION F_CURSERA ( PPIDM NUMBER,PCODE VARCHAR2, Pseqno  number  ) RETURN VARCHAR2  IS

P_ADID_CODE   VARCHAR2(5):= 'COUR';
P_ADID_ID     VARCHAR2(5):= 'COUR';
vetiqueta     varchar2(50);
vsalida       varchar2(300):= 'EXITO';
VMESES        NUMBER:=0;
vsal_dif      varchar2(200);
VPROGRAMA     varchar2(20);
VFECHA_INI    varchar2(20);
vsal_notran    number:=0;
v_valida_f_cour  varchar2(50);
VCODE_DTLX       varchar2(10);
vl_existe       number := 0;
Vnivel          varchar2(4);
VDIFERIDO       varchar2(20);
v_mail         varchar2(50);
V_PROMO     varchar2(50);
Vsyncro            number:= 1; -- va en ceros por que no se sincroniza;
vtipo_serv       varchar2(50);
VAL_NUM_MES      varchar2(3);
vcampus          varchar2(4);

/*
Códigos de Solicitud de servicio:
COLI  CUR COURSERA LIC
COMA CUR COURSERA MAE
COMM CUR COURSERA MAS

se realiza un cambio de flujo se estandariza a las demas certificaciones glovicx 02/05/022
SE REALIZA MODIFICACIÓN  se alinea al nuevo flujo de certificaciones 12.09.022
modificación  para que busque la promocion y la mande a COTA
*/

BEGIN

  -- se obtienen los valores de campus, nivel prog para enviarlos en los paramatros inserta COTA glovicx 04.11.2024
    
     begin

          select distinct t.programa,t.nivel, t.campus
                   INTO vprograma , vnivel, vcampus
           from tztprog t
              where 1=1
                  and  t.pidm = PPIDM
                  and  t.programa = (select DISTINCT VA.SVRSVAD_ADDL_DATA_CDE
                                      FROM svrsvpr v, SVRSVAD VA
                                        where 1=1
                                          and VA.SVRSVAD_ADDL_DATA_SEQ = 1
                                          and V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                          anD V.SVRSVPR_PIDM    =  PPIDM
                                          AND v.SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO)
                  and t.sp = ( select max(t2.sp) from tztprog t2
                               where 1=1
                                and t2.pidm = t.pidm
                                and t2.programa =  t.programa);


                ----dbms_output.PUT_LINE('despues de nivel SEJM:'||vprograma||'-'||  vnivel );
      EXCEPTION WHEN OTHERS THEN

                begin
                   select s1.SORLCUR_PROGRAM, s1.SORLCUR_LEVL_CODE, s1.SORLCUR_CAMP_CODE
                      INTO vprograma , vnivel, vcampus
                    from sorlcur s1
                   where 1=1
                   and s1.sorlcur_pidm = PPIDM
                   and S1.SORLCUR_PROGRAM  = (select DISTINCT VA.SVRSVAD_ADDL_DATA_CDE
                                              FROM svrsvpr v, SVRSVAD VA
                                                where 1=1
                                                  and VA.SVRSVAD_ADDL_DATA_SEQ = 1
                                                  and V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                                  anD V.SVRSVPR_PIDM    =  PPIDM
                                                  AND v.SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO)
                   and s1.SORLCUR_SEQNO = (select max (s2.SORLCUR_SEQNO)  from sorlcur s2
                                            where 1=1
                                              and s1.sorlcur_pidm = s2.sorlcur_pidm 
                                               and S1.SORLCUR_PROGRAM =  S2.SORLCUR_PROGRAM  );


                EXCEPTION WHEN OTHERS THEN
                    vprograma := NULL;
                    vnivel    := null;
                    vcampus   := null;
                    

                 end;


      END;


 -- --dbms_output.put_line(' cursera INICIA 1  '|| PPIDM ||'-'|| PCODE||'-'||Pseqno   );

  BEGIN
         select distinct g.SZT_TIPO_ALIANZA,SZT_SYN_AV
           INTO vtipo_serv, Vsyncro
        from saturn.SZtGECE g
             where 1=1
              AND G.SZT_CODE_SERV = PCODE;
      Exception  When Others then
      vtipo_serv := NULL ;
      Vsyncro   := 1;
      vsalida := 'No se encontro configuración en SZTGECE:::';
     END;


-----CURSERA BUSCA LOS MESES SI ES UNO PASA Y SIN ES 12 NO PASA GLOVIC 29/09/2021
         BEGIN
                select DISTINCT  ZSTPARA_PARAM_ID
                 INTO VCODE_DTLX
                from ZSTPARA z2
                where 1=1
                and z2.ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'
                and z2. ZSTPARA_PARAM_DESC like ('%COURSERA%')
                and Z2.ZSTPARA_PARAM_VALOR   IN(  select DISTINCT  SVRSVAD_ADDL_DATA_CDE
                                    from svrsvpr v,SVRSVAD VA
                                    where 1=1
                                    And SVRSVPR_SRVC_CODE IN (PCODE)
                                     AND  SVRSVPR_PROTOCOL_SEQ_NO = (Pseqno)
                                     AND  SVRSVPR_PIDM    IN (PPIDM)
                                     and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                     and va.SVRSVAD_ADDL_DATA_SEQ = '5');


         EXCEPTION WHEN OTHERS THEN
            --VMESES := 0;
              vsalida := sqlerrm;
              VCODE_DTLX := null ;
             --dbms_output.put_line(' error en codigo dtlle  '|| vsalida    );
--             insert into twpasow( valor1, valor2, valor3,valor4)
--             values ( 'ERRor en tcartera_calcula meses coursera', PPIDM, PNO_SERV,VMESES );
--             commit;
         END;

                     Begin
                        Select count(1)
                            Into vl_existe
                            from GENERAL.GORADID
                        Where GORADID_PIDM = PPIDM
                        And GORADID_ADID_CODE  = p_adid_code;
                 Exception
                    When Others then
                        vl_existe :=0;
                End;

                If vl_existe =0 then

                         begin
                            insert into GORADID values(PPIDM, p_adid_id, p_adid_code, 'WWW_SIU', sysdate, 'COURSERA',null, 0,null);
                         Exception
                         When others then
                         vetiqueta:='Error al insertar Etiqueta'||sqlerrm;
                         vsalida := vetiqueta;
                         end;
                         
                  End if;

                 --  se buscan los tres columnas que pidio fernando para tztcota

     begin
        select distinct g.SZT_MESES, g.SZT_DIFERIDO
             INTO   VMESES, VDIFERIDO
            from svrsvpr v,SVRSVAD VA, SZTCTSIU G
                where 1=1
                    and v.SVRSVPR_SRVC_CODE = PCODE
                    AND v.SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                    and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                    AND  va.SVRSVAD_ADDL_DATA_SEQ = 5
                    AND  v.SVRSVPR_PIDM    = PPIDM
                    and  substr(g.SZT_CODTLE,1,2) =  SUBSTR(F_GetSpridenID(PPIDM),1,2)
                    and  v.SVRSVPR_SRVC_CODE  = g.SZT_CODE_SERV
                    and  TRIM(substr(VA.SVRSVAD_ADDL_DATA_DESC,(instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)+1),4)) = G.SZT_MESES;

         Exception  When Others then

     VMESES  := 01;
     VDIFERIDO  := 0;

     end;



       -- --dbms_output.put_line(' coursera paso 1 mesees y code dtl '|| VMESES ||'-'|| VCODE_DTLX );
     --------cambuamos la forma de buscar el mes gratis regla fer 27.10.022

           begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  VAL_NUM_MES
                from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                AND  SVRSVPR_PIDM    = PPIDM
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '9'; -- pregunta para el mes gratis
                  exception when others then
                    VAL_NUM_MES  := 0;

                  end;


                    ----------cambuamos la forma de buscar el PROMOCION regla fer 27.10.022
             begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  V_PROMO
                from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                AND  SVRSVPR_PIDM    = PPIDM
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '8'; -- pregunta para la promocion
                  exception when others then
                    V_PROMO  := 0;

                  end;

        ----dbms_output.put_line(' paso 3 programa  '|| VPROGRAMA  );
         ---          ----------Buscamos el mail que registro regla fer 08.11.022
             begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  V_mail
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '2'; -- pregunta para el mail de certificaciones
                  exception when others then
                    V_mail  := 'NA';

                  end;



        IF vsalida = 'EXITO' then
               
        
--               begin  ---- se hace un insert en la bitacora para ver los valores que se insertan de inicio glovicx 10.10.2024
--                   insert into tbitsiu (PIDM,CODIGO,MATRICULA, SEQNO,MONTO,ESTATUS,FECHA_CREA,MATERIA,VALOR16,VALOR17 )
--                       values (PPIDM, P_ADID_CODE,'TCOTA', pseqno,VDIFERIDO,VCODE_DTLX, sysdate,vmeses, VAL_NUM_MES,V_PROMO  );
--                    
--                    
--               EXCEPTION WHEN OTHERS THEN
--                  NULL;
--                  vsalida := substr(sqlerrm,1,100);
--
--                     -- --dbms_output.put_line('error al insert tztcota  '||vsalida);
--               END;
      
         ---primero se inserta en la tabla sztcota instrucciones de fernando
              BEGIN
              
              
                 vsalida :=   BANINST1.PKG_FINANZAS_UTLX.F_INS_CONECTA ( PPIDM, null, vcampus, vnivel, vprograma, VCODE_DTLX,pseqno, vmeses, VDIFERIDO,   V_PROMO  ,  trunc(sysdate), trunc(sysdate), P_ADID_CODE, null,VAL_NUM_MES,'A',Vsyncro,V_mail );

              EXCEPTION WHEN OTHERS THEN
                      NULL;
                  vsalida := sqlerrm;

                      --dbms_output.put_line('error al insert tztcota  '||vsalida);
               END;

     --dbms_output.put_line(' coursera paso 2 COTA  '|| vsalida ||'-'|| VCODE_DTLX );
                 begin

                        update SVRSVPR  v
                            set SVRSVPR_SRVS_CODE = 'CL',
                              --  V.SVRSVPR_ACCD_TRAN_NUMBER  = vsal_notran,
                                V.SVRSVPR_ACTIVITY_DATE  = SYSDATE
                        WHERE 1=1
                        and   SVRSVPR_PIDM = PPIDM
                        and   V.SVRSVPR_PROTOCOL_SEQ_NO  = pseqno
                        and  SVRSVPR_SRVC_CODE = pCODE ;

                 exception when others then
                  vsalida := sqlerrm;
                 end;


         -- --dbms_output.put_line(' coursera paso 2 actualiza sazvpr CL  '|| vsalida ||'-'|| VCODE_DTLX );



      END IF;


        -- SE INSERTA LA ETIQUETA GORADID
         -- primero validamos que ese alumno tenga su etiqueta en GORADID--TIIN-- hay que vincular con un poarametrizador code serv vs etiqueta vs code detalle

       ----dbms_output.put_line('coursera  paso 3  Etiqueta   '|| vetiqueta  );

     ------ al final se tiene que actualizar el estatus del servicio y el num de transaccion que regresa reza  segun pagado o activo

               ----dbms_output.put_line(' paso 5  no transc   '|| vsal_notran  );


--INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
  --       VALUES('PASO FINAL F_CURSERA N7:  ' ,PPIDM, PMESES, VFECHA_INI, VPROGRAMA, vetiqueta, vsal_dif, v_valida_f_cour,PDL_DATA_CODE,PDL_DATA_DESC);
  --COMMIT;


return ( vsalida);

exception when others then
--INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
  --       VALUES('PASO ERROR FINAL F_CURSERA TOTAL:  ' ,PPIDM, PMESES, VFECHA_INI, VPROGRAMA, vetiqueta, vsal_dif, v_valida_f_cour,PDL_DATA_CODE,vsalida);


return ( vsalida);

END F_CURSERA;

--
-- Fer v1 22/10/2021
FUNCTION F_MENU_SERV_CERTICA (ppidm in number) Return PKG_SERV_SIU.servicios_type
IS
 cur_servicios BANINST1.PKG_SERV_SIU.servicios_type;
-- SE HACE MODIF PARA NUEVOS CERTIFICACIONES Y MES GRATIS GLOVICX 13.09.022
vserv    VARCHAR2(5);
vnum_periodo  number:=0;
vprograma VARCHAR2(15);
vnivel    VARCHAR2(5);
vcampus   VARCHAR2(5);
vstudy    VARCHAR2(5);

 begin
-- insert into twpasow(valor1, valor2, valor3)
--    values ( 'upsellingMENU-INI_UNOoo', PPIDM,vserv);
--    commit;
 ----vamos a validar si el alumno ya tiene el servicio de sesiones ejecutivas entonces ya no se lo presente en el tapiz de compras --glovicx 15/01/2021
          begin

               select distinct t.programa,t.nivel, t.campus, T.SP
                   INTO vprograma , vnivel, vcampus, vstudy
                from tztprog t
                 where 1=1
                  and  t.pidm = ppidm
                  and t.sp = ( select max(t2.sp) from tztprog t2
                               where 1=1
                                and t2.pidm = t.pidm);


                ----dbms_output.PUT_LINE('despues de nivel SEJM:'||vprograma||'-'||  vnivel );
           EXCEPTION WHEN OTHERS THEN

                begin
                   select SORLCUR_PROGRAM, SORLCUR_LEVL_CODE, SORLCUR_CAMP_CODE
                      INTO vprograma , vnivel, vcampus
                    from sorlcur s1
                   where 1=1
                   and sorlcur_pidm = ppidm
                   and SORLCUR_SEQNO = (select max (SORLCUR_SEQNO)  from sorlcur s2
                                            where 1=1
                                              and s1.sorlcur_pidm = s2.sorlcur_pidm  );


                  EXCEPTION WHEN OTHERS THEN
                    vprograma := NULL;
                    vnivel    := null;
                    vcampus   := null;
                    vstudy    := NULL;

                  end;


          END;




   begin
           SELECT distinct decode(substr(SZTALOL_PROGRAMA,4,2),'LI','SEJL','MA','SEJM') SERVICIO
               into vserv
             FROM sztalol
                where 1=1
                and SZTALOL_PIDM = PPIDM
                  and SZTALOL_ESTATUS = 'A';

   exception when others then
        vserv := 'XX';
    end;

   --si esta con estatus "A" no muestars fechas  regla de fernando

--    insert into twpasow(valor1, valor2, valor3)
--    values ( 'upsellingMENU-INI', PPIDM,vserv);
--    commit;
--
     ----proyecto de CURSERA
     IF vnivel in ('MA','MS'  ) then

         begin

          select distinct counT(datos.ptrm)
          INTO vnum_periodo
            from (
            select  count(F.SFRSTCR_PTRM_CODE ) ,F.SFRSTCR_TERM_CODE, F.SFRSTCR_PTRM_CODE ptrm
            from sfrstcr f, ssbsect bb
            where 1=1
            and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
            and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
            and f.SFRSTCR_PIDM = ppidm
            and F.SFRSTCR_RSTS_CODE  = 'RE'
            and substr(F.SFRSTCR_TERM_CODE,5,1)  not in (8,9)
            and f.SFRSTCR_STSP_KEY_SEQUENCE = vstudy
            AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%H%')
            AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%SESO%')
            AND  F.SFRSTCR_PTRM_CODE  NOT IN (select ZSTPARA_PARAM_VALOR
                                                    from ZSTPARA
                                                    where 1=1
                                                    AND ZSTPARA_MAPA_ID = 'PARTES_MAESTRIA'  )
            group by F.SFRSTCR_TERM_CODE, SFRSTCR_PTRM_CODE
            )datos
            where 1=1;


         exception when otherS then
          vnum_periodo := 0;
         end;

     ELSE  --AQUI CUENTA LIC

        begin

          select distinct counT(datos.ptrm)
          INTO vnum_periodo
            from (
            select  count(F.SFRSTCR_PTRM_CODE ) ,F.SFRSTCR_TERM_CODE , SFRSTCR_PTRM_CODE ptrm
            from sfrstcr f, ssbsect bb
            where 1=1
            and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
            and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
            and f.SFRSTCR_PIDM = ppidm
            and F.SFRSTCR_RSTS_CODE  = 'RE'
            and substr(F.SFRSTCR_TERM_CODE,5,1)  not in (8,9)
            and f.SFRSTCR_STSP_KEY_SEQUENCE = vstudy
            AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%H%')
            AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%SESO%')
            group by F.SFRSTCR_TERM_CODE,SFRSTCR_PTRM_CODE
            )datos
            where 1=1;


         exception when otherS then
          vnum_periodo := 0;
         end;



       END IF;


    open cur_servicios for  SELECT  DISTINCT     A.SVRRSRV_SRVC_CODE AS CODIGO,
                  sv_svvsrvc.f_get_description (A.SVRRSRV_SRVC_CODE) srvc_code_desc
                  , a.SVRRSRV_SEQ_NO
                FROM
                    svrrsrv A,
                    svrrsso b,
                    svvsrvc c,
                    tztprog d
                    WHERE 1=1
                    And d.pidm = ppidm
                    and d.sp in (select max (d1.sp)
                                        from tztprog d1
                                        Where d1.pidm = d.pidm
                                        And d1.programa = d.programa)
                    And a.SVRRSRV_CAMP_CODE = d.campus
                    And a.SVRRSRV_LEVL_CODE  = d.nivel
                    And a.SVRRSRV_STST_CODE = d.estatus
                    AND a.svrrsrv_srvc_code = b.svrrsso_srvc_code
                    AND a.svrrsrv_seq_no = b.svrrsso_rsrv_seq_no
                    AND c.svvsrvc_code = b.svrrsso_srvc_code
                    AND a.svrrsrv_inactive_ind = 'Y'
                    AND a.svrrsrv_web_ind = 'Y'
                    And d.SGBSTDN_STYP_CODE = nvl (a.SVRRSRV_STYP_CODE, SGBSTDN_STYP_CODE)
                  and A.SVRRSRV_SRVC_CODE in  (  SELECT ZSTPARA_PARAM_ID  FROM  SATURN.ZSTPARA
                                                  WHERE ZSTPARA_MAPA_ID ='CERTIFICA_1SS'
                                                  and ZSTPARA_PARAM_ID not in ( vserv  ) ) --('COLF','NIVE','BOAG','TIPR')---SE PASA A UN PARAMETRIZADOR AL FINAL
                  UNION
                   select g.SZT_CODE_SERV, g.SZT_DESCRIPCION,0
                    from saturn.SZtGECE g
                      where 1=1
                        and g.SZT_NIVEL =  vnivel
                        and SZT_TIPO_ALIANZA not in ('Plataformas')
                        and vnum_periodo  between to_number(substr(g.SZT_BIM_COMPRA,1,1)) and to_number(substr(g.SZT_BIM_COMPRA,3,3))
                  ORDER BY 1 ASC;




           return cur_servicios;


    Exception
            When others  then
               vl_error := 'PKG_SERV_SIU_ERROR.cur_servicios: ' || sqlerrm;
           return cur_servicios;
    end F_MENU_SERV_CERTICA;


FUNCTION   F_UPSELLING (PPIDM NUMBER, PSEQNO NUMBER, PCODE VARCHAR2 ,PDL_DATA_DESC varchar2 )  RETURN VARCHAR2
IS

VBACK_FINAN   VARCHAR2(25);
VBACK_PRONO   VARCHAR2(25);
VBACK_EJECUTIVO   VARCHAR2(25);
vprograma     VARCHAR2(15);
vnivel        VARCHAR2(5);
vetiqueta     VARCHAR2(35);
p_adid_code   VARCHAR2(15):= 'EJEC';
p_adid_id     VARCHAR2(25):= 'SESIONES EJECUTIVAS';
verror        varchar2(500);
vvalida_ups   varchar2(100):='N';
vcampus       varchar2(4);
l_regla       NUMBER;
vsal_cursera  VARCHAR2(100);
VFINICIO       DATE;
VFINICIO2     VARCHAR2(36);
VSALIDA       varchar2(500):= 'EXITO';
vsal_notran  NUMBER:=0;

BEGIN
NULL;

------1ro se ejecuta la funcio de huy donde me dice si el alumno ya tiene o no materias de sesion ejecutiva  la salida es un S o N
---- s signidica que ya tiene materias y me salgo no hago nada
----N  significa que no tengo materias y entonces genro todo el proceso

--
 ----A QUIE VAMOS A CALCULAR SI EL SERVICIO ES DE UPPSELING PARA MANDAR LAS FUNCIONES DE REZA Y CHUY



   vprograma :='';
   vnivel := '';


   BEGIN
            SELECT to_DATE(SUBSTR(PDL_DATA_DESC,1,decode(INSTR(PDL_DATA_DESC,'-',1),0,10, INSTR(PDL_DATA_DESC,'-',1))-1),'DD/MM/YYYY')
           --SELECT SUBSTR(PDL_DATA_DESC,1,decode(INSTR(PDL_DATA_DESC,'-',1),0,10, INSTR(PDL_DATA_DESC,'-',1))-1)
           INTO VFINICIO
           FROM DUAL;
                   ----dbms_output.PUT_LINE('calcula fecha ini SEJM:  '||Pserv||'-'||  VCODE ||'---'||VFINICIO);

    EXCEPTION WHEN OTHERS THEN
            VFINICIO := null;
           ----dbms_output.PUT_LINE('error para fechas SEJM:  '||Pserv||'-'||  VCODE ||'-'|| PDL_DATA_DESC||'-'||VFINICIO);

             --insert into twpasow ( valor1, valor2, valor3, VALOR4, VALOR5)
              -- values('upselling_error a la fecha',pPIDM||'-'||PSEQNO||'--> '|| VFINICIO, vprograma, vnivel,SYSDATE  );
             --COMMIT;


    END;

           begin

                 select distinct t.programa,t.nivel, t.campus
                   INTO vprograma , vnivel, vcampus
                 from tztprog t
                  where 1=1
                  and  t.pidm = PPIDM
                  and t.sp = ( select max(t2.sp) from tztprog t2
                               where 1=1
                                and t2.pidm = t.pidm);


                ----dbms_output.PUT_LINE('despues de nivel SEJM:'||vprograma||'-'||  vnivel );
                EXCEPTION WHEN OTHERS THEN

                begin
                   select SORLCUR_PROGRAM, SORLCUR_LEVL_CODE, SORLCUR_CAMP_CODE
                      INTO vprograma , vnivel, vcampus
                    from sorlcur s1
                   where 1=1
                   and sorlcur_pidm = PPIDM
                   and SORLCUR_SEQNO = (select max (SORLCUR_SEQNO)  from sorlcur s2
                                            where 1=1
                                              and s1.sorlcur_pidm = s2.sorlcur_pidm  );


                  EXCEPTION WHEN OTHERS THEN
                    vprograma := NULL;
                    vnivel    := null;
                    vcampus   := null;
                  end;


               END;

           --TO_CHAR(TO_DATE(SUBSTR(VL_VENCIMIENTO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY')


             vvalida_ups := pkg_algoritmo_pidm.f_valida_ups(VFINICIO, PPIDM,vcampus,vnivel  );

             --vvalida_ups := pkg_algoritmo_pidm.f_valida_ups(TO_CHAR(TO_DATE(SUBSTR(VFINICIO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY'),VPIDM,vcampus,vnivel );

            --insert into twpasow ( valor1, valor2, valor3, VALOR4, VALOR5)
                  --values('upselling_resp fun 1',PPIDM||'-'||PSEQNO||'--> '|| VFINICIO, vprograma, vnivel,vvalida_ups  );
               --COMMIT;




     IF vvalida_ups = 'S'  THEN


        null; -- no hace nada
        VSALIDA:='EXITO';

    ELSIF vvalida_ups = 'P'  THEN
       --ESCENARIO 3 PARA LA FUNCION = P
       -- POR REGLA DE CHUY SOLO SE EJECUTA LA FUNCION DE

       vetiqueta:= PKG_RESA.inserta_etiqueta(PPIDM , p_adid_code , p_adid_id   );

        BEGIN

               --SELECT to_DATE(SUBSTR(PDL_DATA_DESC,1,decode(INSTR(PDL_DATA_DESC,'-',1),0,10, INSTR(PDL_DATA_DESC,'-',1))-1),'DD/MM/YYYY')
                SELECT SUBSTR(PDL_DATA_DESC,1,decode(INSTR(PDL_DATA_DESC,'-',1),0,10, INSTR(PDL_DATA_DESC,'-',1))-1)
               INTO VFINICIO2
               FROM DUAL;
                     --  --dbms_output.PUT_LINE('calcula fecha ini SEJM:  '||Pserv||'-'||  VCODE ||'---'||VFINICIO);

               EXCEPTION WHEN OTHERS THEN
                VFINICIO := 'xxxxx';
               ----dbms_output.PUT_LINE('error para fechas SEJM:  '||Pserv||'-'||  VCODE ||'-'|| PDL_DATA_DESC||'-'||VFINICIO);

               --  insert into twpasow ( valor1, valor2, valor3, VALOR4, VALOR5)
                  --  values('upselling_error a la fecha',VPIDM||'-'||Pserv||'--> '|| TO_CHAR(TO_DATE(SUBSTR(VFINICIO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY'), vprograma, vnivel,SYSDATE  );
                -- COMMIT;


               END;

       VBACK_PRONO :=  BANINST1.pkg_algoritmo_pidm.f_up_selling(TO_DATE(VFINICIO2,'DD/MM/YYYY'),vprograma,PPIDM,vnivel )  ;
        VSALIDA:= VBACK_PRONO;

    ELSE
              --insert into twpasow ( valor1, valor2, valor3, VALOR4, VALOR5)
                --values('upselling_inserta en SVRSVAD salida "N"  ',PPIDM||'-'||PSEQNO, vprograma, vnivel ,VSALIDA );
               --COMMIT;


               ----dbms_output.PUT_LINE('ANTES DE IS PARA SEJM:  '||PSEQNO||'-'||  PCODE );


               BEGIN

               --SELECT to_DATE(SUBSTR(PDL_DATA_DESC,1,decode(INSTR(PDL_DATA_DESC,'-',1),0,10, INSTR(PDL_DATA_DESC,'-',1))-1),'DD/MM/YYYY')
                SELECT SUBSTR(PDL_DATA_DESC,1,decode(INSTR(PDL_DATA_DESC,'-',1),0,10, INSTR(PDL_DATA_DESC,'-',1))-1)
               INTO VFINICIO2
               FROM DUAL;
                     --  --dbms_output.PUT_LINE('calcula fecha ini SEJM:  '||Pserv||'-'||  VCODE ||'---'||VFINICIO);

               EXCEPTION WHEN OTHERS THEN
                VFINICIO := 'xxxxx';
               ----dbms_output.PUT_LINE('error para fechas SEJM:  '||Pserv||'-'||  VCODE ||'-'|| PDL_DATA_DESC||'-'||VFINICIO);

                 --insert into twpasow ( valor1, valor2, valor3, VALOR4, VALOR5)
                    --values('upselling_error a la fecha',pPIDM||'-'||PSEQNO||'--> '|| TO_CHAR(TO_DATE(SUBSTR(VFINICIO,1,10),'YYYY/MM/DD'),'DD/MM/YYYY'), vprograma, vnivel,SYSDATE  );
                 --COMMIT;


               END;




                   begin

                       select DISTINCT sztalgo_no_regla
                       into l_regla
                       from sztalgo
                       where 1 = 1
                       and SZTALGO_FECHA_NEW =VFINICIO
                       and sztalgo_camp_code =Vcampus
                       and SZTALGO_LEVL_CODE=Vnivel;

                   exception when others then
                       l_regla := 0;
                   end;






               ----dbms_output.PUT_LINE('antes de envio de funciones SEJM:  '||PPIDM||'-'||PSEQNO||'--> '||VFINICIO2 ||'-'|| vprograma||'-'|| vnivel||'-'|| VFINICIO2 );


              VBACK_PRONO :=  BANINST1.pkg_algoritmo_pidm.f_up_selling(TO_DATE(VFINICIO2,'DD/MM/YYYY'),vprograma,PPIDM,vnivel )  ;

                --insert into twpasow ( valor1, valor2, valor3, VALOR4,VALOR5, VALOR6, valor7)
                      --values('upselling_despuesde f_algoritmo_pidm de funciones',PPIDM||'-'||PSEQNO||'--> '||VFINICIO2, vprograma, vnivel, l_regla,VFINICIO2 ,VBACK_PRONO );
                 --COMMIT;

            IF VBACK_PRONO = 'EXITO' THEN
                 BANINST1.pkg_algoritmo_pidm.p_ejecutivo_pidm(l_regla,PPIDM);




              BEGIN
                VBACK_FINAN := BANINST1.PKG_FINANZAS_BOOTCAMP.F_VALIDA_UPSELLING ( PPIDM,PSEQNO  );
                ----dbms_output.put_line(' paso 4  funcn REZA   '||PPIDM||'-'||   VPROGRAMA||'-'|| PSEQNO||'-'|| VFINICIO  );

                 --insert into twpasow ( valor1, valor2, valor3, VALOR4,VALOR5, VALOR6, valor7)
                     -- values(' PKG_FINANZAS_BOOTCAMP0',PPIDM||'-'||PSEQNO||'--> '||VFINICIO2, vprograma, vnivel, l_regla,VSALIDA ,VBACK_FINAN );
                 --COMMIT;

              EXCEPTION WHEN OTHERS THEN
              VSALIDA :=VBACK_FINAN||'<<->>'||  SQLERRM;
                 --insert into twpasow ( valor1, valor2, valor3, VALOR4,VALOR5, VALOR6, valor7)
                      --values('eroor en  PKG_FINANZAS_BOOTCAMP111',PPIDM||'-'||PSEQNO||'--> '||VFINICIO2, vprograma, vnivel, l_regla,VSALIDA ,VBACK_FINAN );
                 --COMMIT;


              END;

               VSALIDA :=  substr(VBACK_FINAN, 1,instr(VBACK_FINAN,'|',1)-1);
               vsal_notran := substr( VBACK_FINAN,instr(VBACK_FINAN,'|',1)+1);

              --insert into twpasow ( valor1, valor2, valor3, VALOR4,VALOR5, VALOR6, valor7)
                      --values(' f_algoritmo_pidm exito',PPIDM||'-'||PSEQNO||'--> '||VFINICIO2, vprograma, vnivel, l_regla,VFINICIO2 ,VBACK_FINAN );
                 --COMMIT;

               ELSE
                 VBACK_FINAN := 'ERROR EN PRONO';



               END IF;



         --  --dbms_output.PUT_LINE('DESPUES  DE IS PARA SEJM'||  VCODE ||'-'|| VBACK_FINAN|| ' prono-->'|| VBACK_PRONO);
                   IF   VSALIDA != 'EXITO'  OR  VBACK_PRONO != 'EXITO' THEN

                   ----  SI ALGUNO DE LOS PROCESOS EXTRAS DE CHUY O REZA TRUENAN O SON DIF DE EXITO SE CANCELA LA SOLICITUD.
                      UPDATE  SVRSVPR  v
                       SET SVRSVPR_SRVS_CODE = 'CA'
                        WHERE 1=1
                        and   SVRSVPR_PIDM = PPIDM
                        AND   SVRSVPR_PROTOCOL_SEQ_NO =  PSEQNO;

                         --insert into twpasow ( valor1, valor2, valor3, VALOR4, VALOR5)
                         --values('upselling_NO EXITO-CANCELA',pPIDM||'-'||PSEQNO,  'EXEC_P_REZA'||VBACK_FINAN,'EXEC_P_REZA'||VBACK_FINAN, SYSDATE  );

                   VSALIDA  := 'ERROR';---SE MANDA EL ERROR

                   else

                      VSALIDA  := 'EXITO'; ------terminaron con exito los procesos se inserta la eqitqueta en goradit

                      vetiqueta:= PKG_RESA.inserta_etiqueta(PPIDM , p_adid_code , p_adid_id   );

                      ---- todo salio exito entonces actualiza num tran en sasvpr glovicx 17/11/021
                      UPDATE  SVRSVPR  v
                       SET V.SVRSVPR_ACCD_TRAN_NUMBER = vsal_notran,
                            V.SVRSVPR_ACTIVITY_DATE   = sysdate
                        WHERE 1=1
                        and   SVRSVPR_PIDM = PPIDM
                        AND   SVRSVPR_PROTOCOL_SEQ_NO =  PSEQNO;


                   END IF;



    end if;


RETURN VSALIDA;

exception when others then

vsalida := sqlerrm;

return vsalida ;

END F_UPSELLING;

PROCEDURE P_UTELX_PAS  IS

--  PROCESO creado para utelx cuando cambie su estatus a cl hay que mandar la funcion de emir y crear la etiqueta de goradid
--   glovicx utelx 11/11/2021
-- cambio nuevo 25/01/022  glovicx
-- por regla de fernando cuando estre este se hizo el 1er pago y la solcitud debera quedar como CL- concluida 21/01/022
-- ESTE JOB  TIENE LA FUNCIONALIDAD DE LO QUE TENIA EL TRIGER EN SVRSVPR SE CAMBIO PARA SER EJECUTADO X UN JOB.
--  LA TABLA PRINCIPAL DE ESTE PROCESO SZTLXPAS  SE LLENA EN EL TRIGGER DE TBRACCD SOLO PARA UTELX..
-- MODIFICACIÓN SE AGREGO UN PARAMETRO A LA FUNCIÓN DE INSERTA UTELX GLOVICX 29.09.022


vsalida       varchar2(500):='EXITO';
P_ADID_CODE   VARCHAR2(5):= 'UTLX';
P_ADID_ID     VARCHAR2(5):= 'UTLX';
vetiqueta     varchar2(50);
vl_existe     NUMBER:=0;
vestatus      varchar2(2):= 'CL';
VPROGRAMA     varchar2(12);
vsal_notran   number:= 0;
vsal_dif      varchar2(500);
VCODE         VARCHAR2(4);
---
VPIDM         NUMBER;
VSEQNO        NUMBER;
VFECHA_INI    DATE;
P_CODIGO      varchar2(6);
VAL_NUM_MES   NUMBER:=0;
VNIVEL        VARCHAR2(4);
V_FREC_PAGO   VARCHAR2(30);
--            nuevas validaciones glovicx 13.02.2024
 V_montodesc   number:=0;
 V_numdesc   number:=0;

BEGIN
  --VALIDAS LAS OPCINES DE PAGADO
  -- =======================================================
  FOR JUMP IN ( SELECT  SZT_PIDM, SZT_SEQNO, SZT_FECHA_INI,SZT_ESTATUS
                  FROM SATURN.SZTLXPAS X
                  WHERE 1=1
                   AND  X.SZT_ESTATUS = 0) LOOP




   --insert into twpaso  values( 'procc  utelx inicio1  ',JUMP.SZT_PIDM,JUMP.SZT_SEQNO,JUMP.SZT_FECHA_INI );

            begin
                select  SUBSTR(VA.SVRSVAD_ADDL_DATA_CDE,4,2) PROGRAMS, V.SVRSVPR_SRVS_CODE,V.SVRSVPR_SRVC_CODE
                  INTO VNIVEL, VESTATUS , VCODE
                    from svrsvpr v,SVRSVAD VA
                       where 1=1
                        AND  SVRSVPR_PROTOCOL_SEQ_NO = JUMP.SZT_SEQNO
                        AND  SVRSVPR_PIDM   = JUMP.SZT_PIDM
                        and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                        and va.SVRSVAD_ADDL_DATA_SEQ = '1';

            EXCEPTION WHEN OTHERS THEN
             VNIVEL:= null;
             VESTATUS:= null;
             VCODE:= null;
                --dbms_output.put_line('errorn en codigo padre:  '|| sqlerrm  );
             END;


       BEGIN

        select distinct ZSTPARA_PARAM_VALOR
               INTO  VAL_NUM_MES
            from ZSTPARA
            where ZSTPARA_MAPA_ID = 'MESES_GRATIS'
            AND   ZSTPARA_PARAM_ID  =  VCODE
            and   ZSTPARA_PARAM_DESC = VNIVEL;
            EXCEPTION WHEN OTHERS THEN
             VAL_NUM_MES := null;
                --dbms_output.put_line('errorn mrd grstis:  '|| sqlerrm  );
            END;
            
             -- se recupera la frec paso para utlz y conecta glovicx 04.07.2023
                     begin
                        select distinct 
                                    substr(VA.SVRSVAD_ADDL_DATA_DESC,1,instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)-1) as frec
                             INTO   V_FREC_PAGO
                            from svrsvpr v,SVRSVAD VA, SZTCTSIU G
                                where 1=1
                                   -- and v.SVRSVPR_SRVC_CODE = PCODE
                                    AND v.SVRSVPR_PROTOCOL_SEQ_NO = JUMP.SZT_SEQNO
                                    and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                    AND  va.SVRSVAD_ADDL_DATA_SEQ = 5
                                    AND  v.SVRSVPR_PIDM    = JUMP.SZT_PIDM
                                    and  substr(g.SZT_CODTLE,1,2) =  SUBSTR(F_GetSpridenID( JUMP.SZT_PIDM),1,2)
                                    and  v.SVRSVPR_SRVC_CODE  = g.SZT_CODE_SERV
                                    and  TRIM(substr(VA.SVRSVAD_ADDL_DATA_DESC, instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)+1, 3)) = G.SZT_MESES;

                         Exception  When Others then

                     V_FREC_PAGO := '';
                       -- dbms_output.put_line('error al sacar meses y diferiso');
                     end;

                    --dbms_output.put_line('despues  al sacar meses y diferiso  '|| V_FREC_PAGO);

           ----------Buscamos las nuevas columnas de la pantalla de promociones glovicx 16.10.2023
             begin
                    select distinct NVL(SVRSVAD_ADDL_DATA_CDE,0)
                  INTO  V_montodesc
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = VCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = JUMP.SZT_SEQNO
                          AND  SVRSVPR_PIDM    = JUMP.SZT_PIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '20'; -- pregunta para monto descuento
                  exception when others then
                    V_montodesc  := null;
                     --dbms_output.put_line('erroR promociones 20 :  '|| sqlerrm  );
                  end;
            
             begin
                    select distinct nvl(SVRSVAD_ADDL_DATA_CDE,0)
                  INTO  V_numdesc
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = VCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = JUMP.SZT_SEQNO
                          AND  SVRSVPR_PIDM    = JUMP.SZT_PIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '21'; -- pregunta para numero de descuento
                  exception when others then
                    V_numdesc  := null;
                    --dbms_output.put_line('erroR promociones 21 :  '|| sqlerrm  );
                    
                  end;

       --dbms_output.put_line('despues de pregunta 20 y 21   '||VAL_NUM_MES||'-'||V_FREC_PAGO||'-'|| V_montodesc||'-'||V_numdesc );



--- NUEVO PARAMETRO PARA UTELX FRECUENCIA DE PAGOS GLOVICX 03.07.2023
       IF  VCODE = 'UTLX' and  VESTATUS='CL'   then
           begin
           null;
           -- aqui se manda la funcion de Emir para utelx
            -- vsalida :=  baninst1.PKG_UTLX.f_inserta_utlx ( JUMP.SZT_PIDM, baninst1.F_GetSpridenID(JUMP.SZT_PIDM),null, null);
           --  vsalida :=  baninst1.PKG_UTLX.f_inserta_utlx ( JUMP.SZT_PIDM, baninst1.F_GetSpridenID(JUMP.SZT_PIDM),null, null,VAL_NUM_MES,V_FREC_PAGO);
            vsalida :=  baninst1.PKG_UTLX.f_inserta_utlx ( JUMP.SZT_PIDM, baninst1.F_GetSpridenID(JUMP.SZT_PIDM),null, null,VAL_NUM_MES,V_FREC_PAGO,V_montodesc,V_numdesc,null);
           
           
           exception when others then

           vsalida := sqlerrm;
           ----dbms_output.PUT_LINE('erroorrr  en TRIGGER  '||vsalida);


           end;

           -- insert into twpaso  values( 'trigger utelx fesp F emir3  ',JUMP.SZT_PIDM,VCODE,vsalida );
           -- commit;

           ---si el resulktado de la funcion de emir es exito entonces creamos la etiqueta

            ----dbms_output.PUT_LINE('TRIGGER SVRSVPR_POSTUPDATE_UTELX 2: '||  vsalida );
           IF vsalida = 'EXITO'  then

            ----dbms_output.PUT_LINE('TRIGGER SVRSVPR_POSTUPDATE_UTELX 3: '||  vetiqueta || '-'|| p_adid_code ||'-'|| JUMP.SZT_PIDM  );

             -- SE INSERTA LA ETIQUETA GORADID
              --  vetiqueta:= baninst1.PKG_RESA.inserta_etiqueta(JUMP.SZT_PIDM , p_adid_code , p_adid_id   );

               Begin
                        Select count(1)
                            Into vl_existe
                            from GENERAL.GORADID
                        Where GORADID_PIDM = JUMP.SZT_PIDM
                        And GORADID_ADID_CODE  = p_adid_code;
                 Exception
                    When Others then
                        vl_existe :=0;
                End;

                If vl_existe =0 then

                         begin
                            insert into GORADID values(JUMP.SZT_PIDM, p_adid_id, p_adid_code, 'utlx-siu', sysdate, 'UTELX',null, 0,null);
                         Exception
                         When others then
                         vetiqueta:='Error al insertar Etiqueta'||sqlerrm;
                         end;
                  End if;

              ----dbms_output.PUT_LINE('TRIGGER  etiqueta 4 '||  vetiqueta || '-'|| p_adid_code ||'-'|| JUMP.SZT_PIDM  );


            --insert into twpaso  values( 'TRIGGER SVRSVRS fetiqueta4:  ',JUMP.SZT_PIDM,JUMP.SZT_SEQNO,p_adid_id );
            --commit;
          end if;

           --despues se lanza la funcion de gibran regla fernando 25/01/2022
          -- insert into twpaso  values( 'trigger utelx antes de f_gibran  ',JUMP.SZT_PIDM,JUMP.SZT_SEQNO,VSALIDA );
           -- commit;
           -- se realiza un nuevo calculo para sacar el codigo de detalle gibran agrego nuevo parametro p_codigo glovicx 23/03/022

              BEGIN
                 SELECT DISTINCT svrrsso_detl_code
                   INTO P_CODIGO
                   FROM svrrsso so, SVRSVPR v
                    WHERE 1=1
                      and SO.SVRRSSO_SRVC_CODE  = V.SVRSVPR_SRVC_CODE
                      and so.svrrsso_srvc_code =  UPPER(VCODE)
                      and V.SVRSVPR_PIDM  = JUMP.SZT_PIDM
                      AND so.svrrsso_rsrv_seq_no = nvl(v.SVRSVPR_RSRV_SEQ_NO, so.svrrsso_rsrv_seq_no);

              EXCEPTION
                 WHEN OTHERS
                 THEN
                    P_CODIGO := NULL;
              END;





                BEGIN


                         vsal_dif :=  BANINST1.PKG_FINANZAS_UTLX.F_REACTIVA_UTLX ( JUMP.SZT_PIDM, JUMP.SZT_SEQNO, SYSDATE ,P_CODIGO );

                EXCEPTION WHEN OTHERS THEN
                  VSALIDA := vsal_dif||'<<->>'||SQLERRM;

                   ----dbms_output.PUT_LINE('error TRIGGER fGIBRAN '||  JUMP.SZT_PIDM || '-'|| JUMP.SZT_SEQNO ||'-'|| vsal_dif );

                        --insert into twpaso  values( 'ERROOR EN TRIGGER f gibran X2 :  ',JUMP.SZT_PIDM,JUMP.SZT_SEQNO,vsal_dif);
                       -- commit;

                END;

               VSALIDA := vsal_dif; -- substr(vsal_dif, 1,instr(vsal_dif,'|',1)-1);
              -- vsal_notran := substr( vsal_dif,instr(vsal_dif,'|',1)+1);


              ----dbms_output.PUT_LINE('TRIGGER 5 SVRSVPR_POSTUPDATE_UTELX: '||  VCODE || '-'|| vsal_dif||'-'||vsalida );

            --insert into twpaso  values( 'TRIGGER SVRSVRS salida >> f gibran:  ',JUMP.SZT_PIDM,vsal_dif,VSALIDA);
            --commit;

       ---SI LA FUNCION DE GIBRAN REGRESA CERO ENTONCES LE PONEMOS LA FECHA A LA TABLA SZTLXPAS QUE YA LA TOMO Y ESTATUS EN 1
        IF VSALIDA = 'EXITO' THEN
            BEGIN
               UPDATE SZTLXPAS X
                 SET X.SZT_ESTATUS  = 1,
                     X.SZT_FECHA_ASIG_JOB = SYSDATE
                  WHERE 1=1
                   AND   X.SZT_PIDM   =  JUMP.SZT_PIDM
                   AND   X.SZT_SEQNO  = JUMP.SZT_SEQNO;


            EXCEPTION WHEN OTHERS THEN
            null;
           --dbms_output.PUT_LINE('ERROR AL UPDATE SZTLXPASS DE REGRESO: '||  JUMP.SZT_PIDM || '-'|| JUMP.SZT_SEQNO||'-'||vsalida );
            END;
        ELSE
        null;---- en teoria le quita el primer insert de la tabla utelx
           Rollback;
             ----dbms_output.PUT_LINE('SALIDA NO ES SZTLXPASS DE REGRESO: '||  JUMP.SZT_PIDM || '-'|| JUMP.SZT_SEQNO||'-'||vsalida );

         END IF;


       END IF;--FIN FINAL DE LA OPCION UTL Y CL

       --  --dbms_output.PUT_LINE('proceso  6 cambio el estatus final  '||  vsal_dif || '-'|| JUMP.SZT_PIDM  );

commit;
END LOOP;



-- aqui va la segunda parte de job para CONECTA  esta parte se dio la resolución se susy para que de la tabla de cota
--  se tome la misma logica que utel x glovicx 14/03/022
------ seteamo la variable a ceros
VSALIDA := null;

FOR JUMP IN ( SELECT  x.TZTCOTA_PIDM,X.TZTCOTA_SERVICIO
                 FROM TZTCOTA X
                  WHERE 1=1
                   AND  X.TZTCOTA_FLAG = 0
                   and  x.TZTCOTA_ORIGEN = 'CONC') LOOP

            BEGIN
               select SVRSVPR_SRVS_CODE,SVRSVPR_SRVC_CODE
                   INTO VESTATUS , VCODE
                 from SVRSVPR  v
                 WHERE 1=1
                  and   V.SVRSVPR_PIDM = JUMP.TZTCOTA_PIDM
                   and  V.SVRSVPR_PROTOCOL_SEQ_NO  = JUMP.TZTCOTA_SERVICIO;


            EXCEPTION WHEN OTHERS THEN
            VESTATUS  := NULL;
            VCODE     := NULL;
            END;



 --  insert into twpaso  values( 'procc  conecta servicio  ',JUMP.TZTCOTA_PIDM,VCODE,JUMP.TZTCOTA_SERVICIO );



            -- se agrega el parametro a la funcion de Gibran que pidio hoy 23/03/022 glovicx
              BEGIN

                select  SVRSVAD_ADDL_DATA_CDE code_dtl
                     into P_CODIGO
                from svrsvpr v,SVRSVAD VA
                  where 1=1
                    AND  SVRSVPR_PROTOCOL_SEQ_NO = JUMP.TZTCOTA_PIDM
                    AND  SVRSVPR_PIDM   = JUMP.TZTCOTA_SERVICIO
                    and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                    and va.SVRSVAD_ADDL_DATA_SEQ = '5' ---- codigo de detalle para saber los meses
                    ;


              EXCEPTION
                 WHEN OTHERS
                 THEN
                    P_CODIGO := NULL;
                   -- insert into twpaso  values( 'ERROOR EN codtl f gibran Xx2 :  ',JUMP.TZTCOTA_PIDM,JUMP.TZTCOTA_SERVICIO,P_CODIGO);
              END;




 --  insert into twpaso  values( 'procc  utelx inicio1xx  ',JUMP.TZTCOTA_PIDM,VCODE,P_CODIGO );


             BEGIN


                   vsal_dif :=  BANINST1.PKG_FINANZAS_UTLX.F_REACTIVA_UTLX ( JUMP.TZTCOTA_PIDM, JUMP.TZTCOTA_SERVICIO, SYSDATE,P_CODIGO );

             EXCEPTION WHEN OTHERS THEN
                  VSALIDA := vsal_dif||'<<->>'||SQLERRM;

                   ----dbms_output.PUT_LINE('error TRIGGER fGIBRAN '||  JUMP.SZT_PIDM || '-'|| JUMP.SZT_SEQNO ||'-'|| vsal_dif );

                -- insert into twpaso  values( 'ERROOR EN funcion de gibran f gibran X2 :  ',JUMP.TZTCOTA_PIDM,JUMP.TZTCOTA_SERVICIO,vsal_dif);


             END;

                  VSALIDA := vsal_dif;
            --   vsal_notran := substr( vsal_dif,instr(vsal_dif,'|',1)+1);


              ----dbms_output.PUT_LINE('TRIGGER 5 SVRSVPR_POSTUPDATE_UTELX: '||  VCODE || '-'|| vsal_dif||'-'||vsalida );

          --  insert into twpaso  values( 'JOB UTELX-CONECTA salida >> f gibran:  ',JUMP.TZTCOTA_PIDM,vsal_dif,VSALIDA);


       ---SI LA FUNCION DE GIBRAN REGRESA CERO ENTONCES LE PONEMOS LA FECHA A LA TABLA SZTLXPAS QUE YA LA TOMO Y ESTATUS EN 1
        IF VSALIDA = 'EXITO' THEN
            BEGIN
               UPDATE TAISMGR.TZTCOTA X
                 SET X.TZTCOTA_FLAG  = 1,
                     X.TZTCOTA_ACTIVITY      = SYSDATE
                  WHERE 1=1
                   AND   X.TZTCOTA_PIDM      = JUMP.TZTCOTA_PIDM
                   AND   X.TZTCOTA_SERVICIO  = JUMP.TZTCOTA_SERVICIO;


            EXCEPTION WHEN OTHERS THEN
            null;
              --dbms_output.PUT_LINE('ERROR AL UPDATE SZTLXPASS DE REGRESO: '||  JUMP.TZTCOTA_PIDM || '-'|| JUMP.TZTCOTA_SERVICIO||'-'||vsalida );
            END;
        ELSE

        rollback;
             ----dbms_output.PUT_LINE('SALIDA NO ES SZTLXPASS DE REGRESO: '||  JUMP.SZT_PIDM || '-'|| JUMP.SZT_SEQNO||'-'||vsalida );

         END IF;


END LOOP;

--ESTE SI LLEVA COMIT POR QUE NO LO DISPARA UN JOB
commit;

exception when others then
 vsalida := sqlerrm;
           --dbms_output.PUT_LINE('erroorrr  GRAL  EN  JOB UTELX-CONECTA  '||vsalida);



END P_UTELX_PAS ;


FUNCTION F_LIMITA_COMPRA ( P_PIDM NUMBER, P_CODE VARCHAR2 ) RETURN VARCHAR2 IS

-- esta funcion se va ejecutar desde el autoservicio SIU justo despues de que el alumno escoja un accesorio para comprar
-- desde la tienda se ejecuta para ver si el alumno no tiene adeudo y no de los documentos que le solicitan entonces pasa como un exito
-- en caso contrario que no reuna los requisitos de la configuración entonces manda el error.
-- glovicx 15/02/022--
-- cambios 08.06.022-- validar el alumno si su campus esta configurado en la tabla de sztdoca entonces entra al flujo de limitación
-- si no esta su campues entonces pasa normal,
-- si entran al flujo, valida los documentos en la tabla de doca vs sarchkl y si hay 2 documentos al menos validdaos ya lo dejo entrar
--estos son los documentos para LATAM CTTD-CTBD 21.07.022


VESTATUS      VARCHAR2(2):='SI';
vnovalida     number:=0;
vorig         number:=0;
vdig          number:=0;
vadeudo       number:=0;
vdocumentos   varchar2(8):= 'EXITO';
vsalida       varchar2(100):= 'EXITO';
vnivel        VARCHAR2(2);
vstudy        NUMBER:=0;
vmsg_do       varchar2(100);
vmsg_dd       varchar2(100);
vmsg_deuda     varchar2(100);
vcampus       varchar2(4);
vl_existe      varchar2(2);
vetiqueta     varchar2(4);


--P_PIDM   number:=333235;
--P_CODE   varchar2(4):='NIVE';


begin
-- entra como parametros el PIDM y el codigo del accesorio que el alumno escogio

 --  se hacen ajuste para limitar el acceso--
        begin

               --select distinct t.programa,t.nivel, t.campus, T.SP
               SELECT DISTINCT t.nivel, T.SP, T.CAMPUS
                   INTO  vnivel,vstudy, vcampus
                from tztprog t
                 where 1=1
                  and  t.pidm = P_PIDM
                  and t.sp = ( select max(t2.sp) from tztprog t2
                               where 1=1
                                and t2.pidm = t.pidm);


                ----dbms_output.PUT_LINE('despues de nivel SEJM:'||vprograma||'-'||  vnivel );
          EXCEPTION WHEN OTHERS THEN

                begin
                   --select SORLCUR_PROGRAM, SORLCUR_LEVL_CODE, SORLCUR_CAMP_CODE
                   SELECT DISTINCT SORLCUR_LEVL_CODE, SORLCUR_CAMP_CODE
                      INTO  vnivel, vcampus
                    from sorlcur s1
                   where 1=1
                   and sorlcur_pidm = P_PIDM
                   and SORLCUR_SEQNO = (select max (SORLCUR_SEQNO)  from sorlcur s2
                                            where 1=1
                                              and s1.sorlcur_pidm = s2.sorlcur_pidm  );


                  EXCEPTION WHEN OTHERS THEN

                    vnivel    := null;
                    vcampus   := null;

                  end;


           END;
         --  --dbms_output.put_line('LOS PARAMETROS NO PRESENTA EL SERVICIO 1: '|| P_PIDM||'-'|| P_CODE ||'-'||  vnivel||'-'||vstudy );
      -- se buscan los documentos para ver si ya los entrego o estan pendientes
      -- buscamos los documentos del parametrizador que son los que voy a comparar
      --BANINST1.Fvalid_doct


         BEGIN  -- aqui valida el adeudo que tiene se usa la funcion de Vic rmz

             vadeudo:= NVL(BANINST1.PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia_Titulo (P_PIDM),0);



             EXCEPTION WHEN OTHERS THEN
                   BEGIN
                    select case when  sum(TBRACCD_BALANCE) <= 0 then 0 end adeudo
                        INTO vadeudo
                        from tbraccd t
                          where 1=1
                                and TBRACCD_PIDM   = P_PIDM
                                and  TBRACCD_STSP_KEY_SEQUENCE  = vstudy
                                and trunc(T.TBRACCD_EFFECTIVE_DATE) <= trunc(sysdate)
                                ;
                   EXCEPTION WHEN OTHERS THEN
                    vadeudo := 0;
                    END;

             END;
    --  --dbms_output.put_line('LOS PARAMETROS NO PRESENTA EL ADEUDO 2:  '|| vadeudo);


   for  kil in ( select ca.SZT_CODE_DOCU DOCUM, ca.SZT_ADEUDO ADEUDO
                        from SZTDOCA ca
                        where 1=1
                        and CA.SZT_NIVEL = vnivel
                        AND CA.SZT_CODE_ACC = P_CODE
                        and CA.SZT_CAMPUS   = vcampus -- se agrega el campus para la validacion glovicx 07/06/022
               ) loop


        --VALIDO EL ESTUS DEL DOCTO CON LA FUNCION--REGRESA SI O NO

        ---- VESTATUS := BANINST1.Fvalid_docto( P_PIDM, KIL.DOCUM ); se cambia por una funcion nueva glovicx 05.03.2024
        
           begin
               
             select distinct 'SI' 
                  INTO VESTATUS
              from sarchkl kl   
                where 1=1 
                 and kl.SARCHKL_PIDM = P_PIDM
                 AND kl.SARCHKL_ADMR_CODE  =  KIL.DOCUM
                 and kl.SARCHKL_CKST_CODE in (select ZSTPARA_PARAM_VALOR
                                                from ZSTPARA z1
                                                where 1=1
                                                and z1.ZSTPARA_MAPA_ID = 'COMPRA_DOCA'
                                                and z1.ZSTPARA_PARAM_ID =  KIL.DOCUM);
            

            exception when others then
            VSALIDA := SQLERRM;
            VESTATUS := 'NO';
            end;


        -- --dbms_output.put_line('LOS PARAMETROS DE LOOP1:  '|| P_PIDM||'-'||  KIL.DOCUM||'->'|| VESTATUS );

            IF   VESTATUS = 'SI' and substr(KIL.DOCUM,4.1) = 'O'  THEN
              vorig := vorig +1; --cuenta cuantos documentos originales estan validados


            elsif VESTATUS = 'SI' and substr(KIL.DOCUM,4.1) = 'D'  then
              vdig := vdig +1; --cuenta cuantos documentos digitales estan validados

            ELSE --no esta validado los documentos

              IF substr(KIL.DOCUM,4.1) = 'O'  THEN
                vmsg_do := 'Te falta documentación Física';
              elsif substr(KIL.DOCUM,4.1) = 'D'  then
                vmsg_dd := 'Te falta documentación Digital';
              end if;

            vnovalida := vnovalida +1;



            END IF;


       --validamos que los documentos "VALIDADOS"  sean mas que no "VALIDADOS" Y comparamos el adeudo
       IF vadeudo <  kil.ADEUDO   then
         vsalida := 'EXITO';
        -- --dbms_output.put_line('ENTRA A LOS PARAMETROS NO PRESENTA EL SERVICIO 3: '||vadeudo  || ' < '|| kil.ADEUDO ||' = '||  vsalida);
         ELSE
          vsalida := 'ADEUDO';
         vmsg_deuda := 'Presentas adeudo '|| vadeudo;
        -- --dbms_output.put_line('ENTRA A LOS PARAMETROS SI  PRESENTA EL SERVICIO 3X: '|| vadeudo || ' < '|| kil.ADEUDO ||' = '||  vsalida);
       END IF;



      end loop;

        --cerramos el novalida a maximo 2 documentos AUN QUE TENGA MAS
       if vnovalida > 2 then
          vnovalida := 2;
       end if;


      --validamos que los documentos "VALIDADOS"  sean mas que no "VALIDADOS" Y comparamos el adeudo la validacion tiene que ser
      -- los dig o orig mayoro igual  a 2.

      IF VCAMPUS IN ('UTL','USA') AND  (vorig)>= vnovalida   or  (vdig) >= vnovalida  then

         vdocumentos := 'EXITO';
         --dbms_output.put_line('si  ENTRA A LOS PARAMETROS UTL /USAS SI PRESENTA EL SERVICIO 4: '|| vdocumentos);
      ELSIF  (vorig)>= 1   or  (vdig) >= 1 THEN
        vdocumentos := 'EXITO';
        --dbms_output.put_line('si  ENTRA A LOS PARAMETROS LATAM  SI PRESENTA EL SERVICIO 5: '|| vdocumentos);

      ELSE
       vdocumentos := 'NO_VALD';
      end if;




   IF vdocumentos = 'EXITO' AND vsalida = 'EXITO' THEN
    -- --dbms_output.put_line('si/no  ENTRA A LOS PARAMETROS NO PRESENTA EL SERVICIO 5: '|| VSALIDA);
      return (vsalida);
    ELSE

    vsalida := vmsg_do ||';'||vmsg_dd||';'||vmsg_deuda;
      return (vsalida);
    -- --dbms_output.put_line(' ' || VSALIDA||'-'||vdocumentos);
    END IF;




exception when others then
VSALIDA := SQLERRM;

----dbms_output.put_line('ERROR GRAL EL SERVICIO 9: '|| VSALIDA);
return VSALIDA;


end F_LIMITA_COMPRA;


FUNCTION F_CONECTA ( PPIDM NUMBER,PCODE VARCHAR2,seqno  number) RETURN VARCHAR2  IS

P_ADID_CODE   VARCHAR2(5):= 'CONC';
P_ADID_CODE2   VARCHAR2(5):= 'CONE';--ecte accesorio tiene 2 etiquetas por eso se tienen que evaluar regla fer 09.09.022
P_ADID_ID     VARCHAR2(15):= 'CONECTA AUT';
vetiqueta     varchar2(50);
vsalida       varchar2(300):= 'EXITO';
vsal_dif      varchar2(200);
VPROGRAMA     varchar2(20);
VFECHA_INI    varchar2(20);
vsal_notran    number:=0;
v_valida_f_cour  varchar2(50);
VMONTO          NUMBER :=0;
vl_existe       NUMBER :=0;
vnivel          varchar2(4);
vcampus         varchar2(4);
VMESES          varchar2(6);
VDIFERIDO       varchar2(6);
vcve_dtl_papa   varchar2(6);
VAL_NUM_MES     number:=0;
Vsyncro            number:= 1;
V_PROMO        VARCHAR2(10):=0;
v_mail            varchar2(50);
V_FREC_PAGO   VARCHAR2(30);


--modificacion para alinear al nuevo flujo de cursos que fernando asigno glovicx 12.09.022
--  se agrega la columna frecuencia de pago 24.07.2023 glovicx 

BEGIN

--NOTA EL PARAMETRO P_CODIGO VIENE NULL DESDE EL TRIGGER SE VA CALCULAR AQUI EN BASE AL PARAMETRIZADOR GLOVICX 16/02/022

--INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5 )
       -- VALUES('PASO INICIO DE F_Conecta 1 ' ,PPIDM, seqno, PCODE, PMESES );
 --COMMIT;




         --dbms_output.put_line(' paso 2 fecha inicio   '|| VFECHA_INI  );
           BEGIN    -----------------recupera la parte de periodo que solicito el alumno
           select DISTINCT SVRSVAD_ADDL_DATA_CDE
                INTO VPROGRAMA
                from svrsvpr v,SVRSVAD VA
                where SVRSVPR_SRVC_CODE = PCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = seqno
                AND  SVRSVPR_PIDM    = PPIDM
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                and va.SVRSVAD_ADDL_DATA_SEQ = '1'---fechas inicio parte prd
          ;
          EXCEPTION WHEN OTHERS THEN
            VPROGRAMA:='';
            vsalida := sqlerrm;
             --dbms_output.put_line(' error en programa   '|| vsalida  );
          END;

       -- dbms_output.put_line(' paso 1 programa  '|| VPROGRAMA  );

           begin

                 select distinct t.nivel, t.campus
                   INTO  vnivel, vcampus
                 from tztprog t
                  where 1=1
                  and  t.pidm = PPIDM
                  and  T.PROGRAMA  = VPROGRAMA  ;


                --DBMS_OUTPUT.PUT_LINE('despues de nivel SEJM:'||vprograma||'-'||  vnivel );
                EXCEPTION WHEN OTHERS THEN

                begin
                   select  SORLCUR_LEVL_CODE, SORLCUR_CAMP_CODE
                      INTO vnivel, vcampus
                    from sorlcur s1
                   where 1=1
                   and sorlcur_pidm = PPIDM
                   and SORLCUR_SEQNO = (select max (SORLCUR_SEQNO)  from sorlcur s2
                                            where 1=1
                                              and s1.sorlcur_pidm = s2.sorlcur_pidm  );


                  EXCEPTION WHEN OTHERS THEN
                   -- vprograma := NULL;
                    vnivel    := null;
                    vcampus   := null;
                  end;


           END;

       --  se buscan los tres columnas que pidio fernando para tztcota

     begin
          select distinct g.SZT_MESES, g.SZT_DIFERIDO,G.SZT_CODTLE,
                    substr(VA.SVRSVAD_ADDL_DATA_DESC,1,instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)-1) as frec
             INTO   VMESES, VDIFERIDO,vcve_dtl_papa, V_FREC_PAGO
            from svrsvpr v,SVRSVAD VA, SZTCTSIU G
                where 1=1
                    and v.SVRSVPR_SRVC_CODE = PCODE
                    AND v.SVRSVPR_PROTOCOL_SEQ_NO = SEQNO
                    and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                    AND  va.SVRSVAD_ADDL_DATA_SEQ = 5
                    AND  v.SVRSVPR_PIDM    = PPIDM
                    and  substr(g.SZT_CODTLE,1,2) =  SUBSTR(F_GetSpridenID(PPIDM),1,2)
                    and  v.SVRSVPR_SRVC_CODE  = g.SZT_CODE_SERV
                    and  TRIM(substr(VA.SVRSVAD_ADDL_DATA_DESC, instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)+1, 3)) = G.SZT_MESES;


         Exception  When Others then

     VMESES  := 01;
     VDIFERIDO  := 0;
       -- dbms_output.put_line('error al sacar meses y diferiso');
     end;

    -- dbms_output.put_line('despues  al sacar meses y diferiso  '|| VMESES ||'-'|| VDIFERIDO);


                 Begin
                        Select count(1)
                            Into vl_existe
                            from GENERAL.GORADID
                        Where GORADID_PIDM = PPIDM
                           And (GORADID_ADID_CODE  = p_adid_code
                             or GORADID_ADID_CODE  = p_adid_code2 );

                 Exception
                    When Others then
                        vl_existe :=0;
                End;

                If vl_existe =0 then

                         begin
                            insert into GORADID values(PPIDM, p_adid_id, p_adid_code, 'conect-siu', sysdate, 'conect',null, 0,null);
                         Exception
                         When others then
                         vetiqueta:='Error al insertar Etiqueta'||sqlerrm;
                         end;
                         
                    vl_existe := 1;  
                                             
                  End if;

         --    dbms_output.put_line('antes de mes grstis:  '|| PCODE||'-'|| VNIVEL );
     /*     BEGIN

            select distinct ZSTPARA_PARAM_VALOR
               INTO  VAL_NUM_MES
            from ZSTPARA
            where ZSTPARA_MAPA_ID = 'MESES_GRATIS'
            AND   ZSTPARA_PARAM_ID  =  PCODE
            and   ZSTPARA_PARAM_DESC = VNIVEL;
           EXCEPTION WHEN OTHERS THEN
             VAL_NUM_MES := 0;
                dbms_output.put_line('errorn mrd grstis:  '|| sqlerrm  );
           END ;
        */



          IF VMESES >= 1  and vl_existe = 1 then
            -- INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
            -- VALUES('PASO INICIO DE F_CONECTA NO4 ' ,PPIDM, seqno, VFECHA_INI, VPROGRAMA, VMESES, vsal_dif, vl_existe,P_ADID_ID,P_ADID_CODE);
                --COMMIT;

             --- segun el orden que nos dio Susy en elmail 10/02/2022
             -- primero la tabla
             --REGLA DE FERNANDO HAY QU EVALIDAR si es un accesorio de sincronia en sztgece

             begin
                 select distinct SZT_SYN_AV
                   into Vsyncro
                    from sztgece
                    where 1=1
                    and SZT_CODE_SERV = PCODE
                    and SZT_NIVEL        =  VNIVEL
                    ;
             exception when others then
              Vsyncro := 1;
             end;

            ----------cambuamos la forma de buscar el mes gratis regla fer 27.10.022

           begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  VAL_NUM_MES
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = SEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '9'; -- pregunta para el mes gratis
                  exception when others then
                    VAL_NUM_MES  := 0;

                  end;


                    ----------cambuamos la forma de buscar el PROMOCION regla fer 27.10.022
             begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  V_PROMO
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = SEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '8'; -- pregunta para la promocion
                  exception when others then
                    V_PROMO  := 0;

                  end;

           ----------Buscamos el mail que registro regla fer 08.11.022
             begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  V_mail
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = SEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '2'; -- pregunta para el mail de certificaciones
                  exception when others then
                    V_mail  := 'NA';

                  end;

                         ----regla de fernando 11.11.2022 ENVÍO X MAIL  glovicx
              -- valor  "1"  = 0
              -- valor  "1"  = 5
                IF Vsyncro  = 1  THEN
                  Vsyncro := 0;
                  ELSE
                  Vsyncro := 5;
                 END IF;

             --dbms_output.put_line('PARA INSERTAR   '|| VMESES ||'-'|| VDIFERIDO||'-'||Vsyncro||'-'||vcve_dtl_papa||'-'||V_PROMO||'-'||VAL_NUM_MES);
             BEGIN
                        null;
                        --- se comento esta lines por que hay que liberarse en la noche x lo que implica glovicx 07.08.2023
                 vsalida :=   BANINST1.PKG_FINANZAS_UTLX.F_INS_CONECTA ( PPIDM, null, null, null, null, vcve_dtl_papa,seqno, VMESES, VDIFERIDO,V_PROMO,  trunc(sysdate), trunc(sysdate), P_ADID_CODE, null,VAL_NUM_MES,'A',Vsyncro,V_mail,V_FREC_PAGO);

              EXCEPTION WHEN OTHERS THEN
                  NULL;
                  vsalida := sqlerrm;

                    --  dbms_output.put_line('error al insert tztcota  '||vsalida);
             END;


              -- dbms_output.put_line(' paso 4  TERMINO fun f_reactiva utlx    '|| vsalida  );

             -- al último cambiamos el  estatus--

                begin

                        update SVRSVPR  v
                            set v.SVRSVPR_SRVS_CODE = 'CL'
                               --- V.SVRSVPR_ACCD_TRAN_NUMBER =  vsal_notran
                        WHERE 1=1
                        and   SVRSVPR_PIDM = PPIDM
                        and   V.SVRSVPR_PROTOCOL_SEQ_NO  = seqno
                        --and  SVRSVPR_SRVC_CODE = VCODE
                        ;

                         vsalida := 'EXITO';

               exception when others then
                  vsalida := sqlerrm;
               end;
               --  INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8 )
              --  VALUES('PASO DE F_Conecta estatus CL 4' ,PPIDM, seqno, PCODE, VPROGRAMA, vetiqueta, vsal_dif, vsalida);
                --COMMIT;


         end IF;


             --  dbms_output.put_line(' paso 5  TERMINO TODO EL PROCESO    '|| vsalida  );


   return ( vsalida);


exception when others then
    -- INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7)
    --  VALUES('PASO ERROR FINAL F_Conecta TOTAL:  ' ,PPIDM, PMESES, VFECHA_INI, VPROGRAMA, vetiqueta,vsalida);

--dbms_output.put_line(' error gral f_conecta   '|| sqlerrm  );
return ( vsalida);

END F_CONECTA;



FUNCTION F_VOXY ( PPIDM NUMBER,VCODE VARCHAR2, seqno  number  ) RETURN VARCHAR2  IS
/* SE LIBERA LA FUNCIONALIDAD DE VOXY 14/04/022  GLOVICX
*/
P_ADID_CODE   VARCHAR2(5):= 'VOXY';
P_ADID_ID     VARCHAR2(5):= 'VOXY';
vetiqueta     varchar2(50):= null;
vsalida       varchar2(300):= 'EXITO';
VMESES        NUMBER:=0;
vsal_dif      varchar2(200);
VPROGRAMA     varchar2(20);
vl_existe     NUMBER ;
vcve_dtl_papa    varchar2(6);
v_mail           varchar2(50);


BEGIN



        -- SE INSERTA LA ETIQUETA GORADID
         -- primero validamos que ese alumno tenga su etiqueta en GORADID--TIIN-- hay que vincular con un poarametrizador code serv vs etiqueta vs code detalle
                 Begin
                        Select count(1)
                            Into vl_existe
                            from GENERAL.GORADID
                        Where GORADID_PIDM = PPIDM
                        And GORADID_ADID_CODE  = p_adid_code;
                 Exception
                    When Others then
                        vl_existe :=0;
                End;

                If vl_existe =0 then

                         begin
                            insert into GORADID values(PPIDM, p_adid_id, p_adid_code, 'WWW_SIU', sysdate, 'VOXY',null, 0,null);
                         Exception
                         When others then
                         vetiqueta:='Error al insertar Etiqueta'||sqlerrm;
                         end;
                  End if;


        --dbms_output.put_line('paso etiqueta  f_voxy '|| vetiqueta||'-'|| vl_existe  );

     ------ al final se tiene que actualizar el estatus del servicio y el num de transaccion que regresa reza  segun pagado o activo
           --       INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
            --      VALUES('PASO INICIO DE F_voxy NO4:  ' ,PPIDM, vetiqueta, PMESES, VPROGRAMA, seqno, VCODE, vl_existe,PDL_DATA_CODE,PDL_DATA_DESC);
                 -- COMMIT;

         -- se calcula el Codigo padre nueva regla 04/04/022 DE FERNANDO Y VIC RMZ
       -- para la tabla de TZTCOTA si va el codigo padre y para el servicio y edcota que yo inserto va codigo hijo

            begin
                select distinct z1.ZSTPARA_PARAM_ID
                  INTO vcve_dtl_papa
                    from ZSTPARA z1
                    where 1=1
                    and z1.ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'
                    and z1.ZSTPARA_PARAM_DESC LIKE ('%VOXY%')
                    and z1.ZSTPARA_PARAM_VALOR in (select  SVRSVAD_ADDL_DATA_CDE code_dtl
                                                         from svrsvpr v,SVRSVAD VA
                                                           where 1=1
                                                            AND  SVRSVPR_PROTOCOL_SEQ_NO = seqno
                                                            AND  SVRSVPR_PIDM   = PPIDM
                                                            and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                                            and va.SVRSVAD_ADDL_DATA_SEQ = '5') ;



            EXCEPTION WHEN OTHERS THEN
             vcve_dtl_papa := null;

             END;

                    ----------Buscamos el mail que registro regla fer 08.11.022
             begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  V_mail
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = VCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = SEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '2'; -- pregunta para el mail de certificaciones
                  exception when others then
                    V_mail  := 'NA';

                  end;



                      BEGIN

                      vsalida :=   BANINST1.PKG_FINANZAS_UTLX.F_INS_CONECTA ( PPIDM, null, null, null, null, vcve_dtl_papa,seqno, null, null,null,  trunc(sysdate), trunc(sysdate), P_ADID_CODE, 'A',null,null,null,v_mail );



                      EXCEPTION WHEN OTHERS THEN
                      NULL;
                      vsalida := substr(sqlerrm,1,100);

                      --dbms_output.put_line('error al insert tztcota  '||vsalida);
                      END;
              ----dbms_output.put_line('paso insert COTA  f_unicef '|| vetiqueta||'-'|| vsalida  );


       IF vsalida  = 'EXITO' THEN
                 begin

                        update SVRSVPR  v
                            set SVRSVPR_SRVS_CODE = 'CL',
                              --  V.SVRSVPR_ACCD_TRAN_NUMBER  = vsal_notran,
                                V.SVRSVPR_ACTIVITY_DATE  = SYSDATE
                        WHERE 1=1
                        and   SVRSVPR_PIDM = PPIDM
                        and   V.SVRSVPR_PROTOCOL_SEQ_NO  = seqno
                        and  SVRSVPR_SRVC_CODE = VCODE ;

                 exception when others then
                  vsalida := substr(sqlerrm,1,99);

                 end;
                ----dbms_output.put_line(' paso 5 VOXY UPDATE SZVPR A CL  '|| vsalida  );


        END IF;



     return (vsalida);


end F_VOXY;


FUNCTION F_UNICEF ( PPIDM NUMBER,VCODE VARCHAR2, PDL_DATA_CODE VARCHAR2,PDL_DATA_DESC VARCHAR2, seqno  number,PMESES NUMBER ) RETURN VARCHAR2  IS

P_ADID_CODE   VARCHAR2(5):= 'UNIC';
P_ADID_ID     VARCHAR2(5):= 'UNIC';
vetiqueta     varchar2(50);
vsalida       varchar2(300):= 'EXITO';
VMESES        NUMBER:=0;
vsal_dif      varchar2(200);
VPROGRAMA     varchar2(20);
VFECHA_INI    varchar2(20);
vsal_notran    number:=0;
v_valida_f_cour  varchar2(50);
vl_existe      number:=0;
vcve_dtl_papa   varchar2(20);
VDIFERIDO       varchar2(20);
V_mail           varchar2(50);

/*
este proceso se ejecuta desde el trigger de tbraccd cuando el primer pago ya se realizo es la regla de fernando en ese momento
se ejecuta este procedimiento que contiene la segunda parte del proceso para los pagos posteriores
glovicx 28/03/022
modif se agrego una modif a peticion de fernando dia 04/04/022 glovicx
--modificacion para alinear al nuevo flujo de cursos que fernando asigno glovicx 12.09.022
*/

BEGIN

     --INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7 )
      --VALUES('PASO INICIO DE F_unicef' ,PPIDM, VCODE,PDL_DATA_CODE,PDL_DATA_DESC, seqno, PMESES );
--COMMIT;


----dbms_output.put_line('inicio f_unicef '|| PPIDM ||'-'||VCODE ||'-'|| PDL_DATA_CODE ||'-'||PDL_DATA_DESC ||'-'|| seqno ||'-'||PMESES );

--        BEGIN
--            select distinct SUBSTR(ZSTPARA_PARAM_ID,1,INSTR(ZSTPARA_PARAM_ID,',',1)-1 ) MESES
--                INTO  VMESES
--              from ZSTPARA
--               where 1=1
--                AND ZSTPARA_MAPA_ID = 'COSTOS_COURSERA'
--                AND ZSTPARA_PARAM_DESC = PDL_DATA_CODE;
--        EXCEPTION WHEN OTHERS THEN
--        VMESES := 0;
--
--        END;
--
        ----dbms_output.put_line(' paso 1 mesees  '|| PMESES  );
      /*   BEGIN    -----------------recupera la parte de periodo que solicito el alumno
           select DISTINCT SUBSTR(SVRSVAD_ADDL_DATA_DESC,1,decode(INSTR(SVRSVAD_ADDL_DATA_DESC,'|',1),0,10, INSTR(SVRSVAD_ADDL_DATA_DESC,'|',1))) finicio
                INTO VFECHA_INI
                from svrsvpr v,SVRSVAD VA
                where SVRSVPR_SRVC_CODE = VCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = seqno
                AND  SVRSVPR_PIDM    = PPIDM
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                and va.SVRSVAD_ADDL_DATA_SEQ = '7'---fechas inicio parte prd
          ;
          EXCEPTION WHEN OTHERS THEN
            VFECHA_INI:='';
            vsalida  := 'error fecha inicio'||substr(sqlerrm,1,80);
          END;
         */

         ----dbms_output.put_line(' paso 2 fecha inicio   '|| VFECHA_INI  );
           BEGIN    -----------------recupera la parte de periodo que solicito el alumno
           select DISTINCT SVRSVAD_ADDL_DATA_CDE
                INTO VPROGRAMA
                from svrsvpr v,SVRSVAD VA
                where SVRSVPR_SRVC_CODE = VCODE
                AND  SVRSVPR_PROTOCOL_SEQ_NO = seqno
                AND  SVRSVPR_PIDM    = PPIDM
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                and va.SVRSVAD_ADDL_DATA_SEQ = '1'---fechas inicio parte prd
          ;
          EXCEPTION WHEN OTHERS THEN
            VPROGRAMA:='';
            vsalida := 'error vprograma'||substr(sqlerrm,1,80);
             ----dbms_output.put_line(' error en programa   '|| vsalida  );
          END;

        ----dbms_output.put_line(' paso 3 programa  '|| VPROGRAMA  );
        --INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
       -- VALUES('PASO INICIO DE F_CURSERA NO3  ' ,PPIDM, seqno, VFECHA_INI, VPROGRAMA, PMESES, vsal_dif, v_valida_f_cour,PDL_DATA_CODE,PDL_DATA_DESC);
        --COMMIT;



        -- SE INSERTA LA ETIQUETA GORADID
         -- primero validamos que ese alumno tenga su etiqueta en GORADID--TIIN-- hay que vincular con un poarametrizador code serv vs etiqueta vs code detalle
                 Begin
                        Select count(1)
                            Into vl_existe
                            from GENERAL.GORADID
                        Where GORADID_PIDM = PPIDM
                        And GORADID_ADID_CODE  = p_adid_code;
                 Exception
                    When Others then
                        vl_existe :=0;
                End;

                If vl_existe =0 then

                         begin
                            insert into GORADID values(PPIDM, p_adid_id, p_adid_code, 'WWW_SIU', sysdate, 'UNICEF',null, 0,null);
                         Exception
                         When others then
                         vetiqueta:='Error al insertar Etiqueta'||sqlerrm;
                         end;
                  End if;


        --dbms_output.put_line('paso etiqueta  f_unicef '|| vetiqueta||'-'|| vl_existe  );

     ------ al final se tiene que actualizar el estatus del servicio y el num de transaccion que regresa reza  segun pagado o activo
                 -- INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
                 -- VALUES('PASO INICIO DE F_unicef NO4:  ' ,PPIDM, vetiqueta, PMESES, VPROGRAMA, seqno, VCODE, vl_existe,PDL_DATA_CODE,PDL_DATA_DESC);
                 -- COMMIT;

     ---por instrucciones de Fer y VicRmz se va insertar en la tabla de COTA que es la función F_INS_CONECTA el codigo de detalle PADRE (NO-convertido)
    -- se calcula el Codigo padre nueva regla 04/04/022

            begin
                SELECT DISTINCT datos.cve_dtl
                    into  vcve_dtl_papa
                        FROM (
                        select distinct  ZSTPARA_PARAM_DESC cve_dtl,
                                          TO_NUMBER(substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1  )) NUM
                                           ,decode ( substr(ZSTPARA_PARAM_ID,1,instr(ZSTPARA_PARAM_ID,',',1)-1  ),1,' UN PAGO ',' MESES '  )
                                                           ||  '|||' ||substr(ZSTPARA_PARAM_VALOR, instr(ZSTPARA_PARAM_VALOR,',',1)+1)
                                                              MESES
                                                from ZSTPARA
                                                  where 1=1
                                                    and ZSTPARA_MAPA_ID = 'COST_UNICEF_1SS'
                                                    and substr(ZSTPARA_PARAM_DESC,1,2) = substr(F_GetSpridenID(ppidm),1,2)
                                                    and substr(ZSTPARA_PARAM_ID,instr(ZSTPARA_PARAM_ID,',',1)+1,5  ) = substr(VPROGRAMA,4,2)

                                                    ORDER BY 2
                        ) DATOS,ZSTPARA z2
                        where 1=1
                        and z2.ZSTPARA_PARAM_ID = DATOS.cve_dtl
                        and z2.ZSTPARA_MAPA_ID = 'ACC_DIFERIDO'
                        and z2.ZSTPARA_PARAM_VALOR   = PDL_DATA_CODE--- este es el codtlle hijo
                        and datos.num = NVL(PMESES, datos.num)
                        ORDER BY 1
                        ;


            exception when others then
            vcve_dtl_papa    := null;
            end;


              --  se buscan los tres columnas que pidio fernando para tztcota

     begin
        select distinct g.SZT_MESES, g.SZT_DIFERIDO
             INTO   VMESES, VDIFERIDO
            from svrsvpr v,SVRSVAD VA, SZTCTSIU G
                where 1=1
                    and v.SVRSVPR_SRVC_CODE = VCODE
                    AND v.SVRSVPR_PROTOCOL_SEQ_NO = SEQNO
                    and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                    AND  va.SVRSVAD_ADDL_DATA_SEQ = 5
                    AND  v.SVRSVPR_PIDM    = PPIDM
                    and  substr(g.SZT_CODTLE,1,2) =  SUBSTR(F_GetSpridenID(PPIDM),1,2)
                    and  v.SVRSVPR_SRVC_CODE  = g.SZT_CODE_SERV
                    and  substr(VA.SVRSVAD_ADDL_DATA_DESC,1,(instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)-1)) = G.SZT_MESES;

         Exception  When Others then

     VMESES  := 01;
     VDIFERIDO  := 0;

     end;

                   ----------Buscamos el mail que registro regla fer 08.11.022
             begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  V_mail
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = vCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = SEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '2'; -- pregunta para el mail de certificaciones
                  exception when others then
                    V_mail  := 'NA';

                  end;




                      BEGIN


                      vsalida :=   BANINST1.PKG_FINANZAS_UTLX.F_INS_CONECTA ( PPIDM, null, null, null, null, vcve_dtl_papa,seqno, vmeses, VDIFERIDO,null,  trunc(sysdate), trunc(sysdate), P_ADID_CODE, 'A',null,null,null,v_mail );

                      EXCEPTION WHEN OTHERS THEN
                      NULL;
                      vsalida := substr(sqlerrm,1,100);

                      --dbms_output.put_line('error al insert tztcota  '||vsalida);
                      END;
            --  --dbms_output.put_line('paso insert COTA  f_unicef '|| vetiqueta||'-'|| vsalida  );

          -- YA NO SE USA ESTA FUNCION X INSTRUUCIONES DE gIBRAN GLOVICX 04/04/022
           /*   BEGIN
               -- vsal_dif :=  PKG_FINANZAS_REZA.F_ACC_DIFERIDO( PPIDM, PDL_DATA_CODE, PMESES, VPROGRAMA, seqno, VCODE );
                --dbms_output.put_line(' paso 4  funcn REZA-unicef   '||PPIDM||'-'|| PDL_DATA_CODE||'-'|| PMESES||'-'|| VPROGRAMA||'-'|| seqno||'-'|| VFECHA_INI||'-'|| vsal_dif  );

              EXCEPTION WHEN OTHERS THEN
              VSALIDA := vsal_dif||'<<->>'|| substr( SQLERRM,1,80);
              INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
                VALUES('PASO INICIO DE F_UNICEF ERROR EN DE GIBRAN:  ' ,PPIDM, seqno, VCODE, VPROGRAMA, PMESES, vsal_dif, vsal_notran,PDL_DATA_CODE,VSALIDA);
               -- COMMIT;

              END;

               --VSALIDA :=  substr(vsal_dif, 1,instr(vsal_dif,'|',1)-1);
             --  vsal_notran := substr( vsal_dif,instr(vsal_dif,'|',1)+1);
              */


               -- INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
               -- VALUES('PASO INICIO DE F_UNICEF NO5:  ' ,PPIDM, seqno, VCODE, VPROGRAMA, PMESES, vsal_dif, vsal_notran,PDL_DATA_CODE,VSALIDA);
                --COMMIT;






       IF vsalida  = 'EXITO' THEN
                 begin

                        update SVRSVPR  v
                            set SVRSVPR_SRVS_CODE = 'CL',
                              --  V.SVRSVPR_ACCD_TRAN_NUMBER  = vsal_notran,
                                V.SVRSVPR_ACTIVITY_DATE  = SYSDATE
                        WHERE 1=1
                        and   SVRSVPR_PIDM = PPIDM
                        and   V.SVRSVPR_PROTOCOL_SEQ_NO  = seqno
                        and  SVRSVPR_SRVC_CODE = VCODE ;

                 exception when others then
                  vsalida := substr(sqlerrm,1,99);

                 end;
                --dbms_output.put_line(' paso 5  UPDATE SZVPR A CL  '|| vsalida  );


        END IF;

             --commit;


--INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
  --                VALUES('PASO INICIO DE F_CURSERA NO6:  ' ,PPIDM, seqno, VFECHA_INI, VPROGRAMA, PMESES, vsal_dif, v_valida_f_cour,PDL_DATA_CODE,PDL_DATA_DESC);
    --                 COMMIT;

----dbms_output.put_line(' paso 7  update    '|| vsal_dif  );

---- al final se manda la funcion de PACO PARA EL PRONOSTICO---
   --v_valida_f_cour  := BANINST1.PKG_SENIOR.F_ALUMNOS_COUR ( PPIDM, TO_DATE(VFECHA_INI, 'DD/MM/YYYY'),VPROGRAMA );
        ----dbms_output.put_line(' paso 8  funcion CHUY    '|| v_valida_f_cour  );


--INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
  --       VALUES('PASO FINAL F_CURSERA N7:  ' ,PPIDM, PMESES, VFECHA_INI, VPROGRAMA, vetiqueta, vsal_dif, v_valida_f_cour,PDL_DATA_CODE,PDL_DATA_DESC);
  --COMMIT;


return ( vsalida);

exception when others then
--INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7, VALOR8, valor9, valor10 )
 --- VALUES('PASO ERROR FINAL F_unicef TOTAL:  ' ,PPIDM, PMESES, VFECHA_INI, VPROGRAMA, vetiqueta, vsal_dif, v_valida_f_cour,PDL_DATA_CODE,vsalida);
NULL;

return ( vsalida);

END F_UNICEF;


PROCEDURE P_CERTIFICA_AUTO (ppidm  number, pseqno  number, pcode varchar2  ) is
/*
Se creo este procedimiento para ser ejecutado desde el trigger fe TBRACCD de esta manera toda la funcionalidad de las
certificaciones que antes estaban ahí se pasaron a este proceso y asi ya no se toca el trigger, glovicx 26/04/022
*/

VCODE_DTLX    VARCHAR2(50);
VMESES        NUMBER:=0;
VSALIDA       VARCHAR2(1000);
VDESC_DTL     VARCHAR2(100);
vbandera      varchar2(50);

BEGIN

null;

--dbms_output.PUT_LINE('INICIO certif auto :: '||  ppidm||'-'||pcode);


IF  pcode = 'UTLX'  THEN
vbandera := 'opcion UTELX';

            BEGIN
              UPDATE SVRSVPR V
               SET V.SVRSVPR_SRVS_CODE = 'CL',
                   V.SVRSVPR_ACTIVITY_DATE  = SYSDATE
               WHERE 1=1
                AND  V.SVRSVPR_PROTOCOL_SEQ_NO = pseqno
                AND  V.SVRSVPR_PIDM            = ppidm
                ;

             EXCEPTION WHEN OTHERS THEN
             NULL;
             vsalida := 'error en cambio de  estatus sasvpr'  || sqlerrm;
             END;
             --- nuevo flujo para ejecutar los procesos de emir y gibran 28/01/2022
             -- se va insertar en una tabla de paso cada que entre aqui.
             -- DESPUES SE VA EJECUTAR DESDE UN JOB una funcion de utelx en pkg_serv_siu.
               BEGIN

                 INSERT INTO SATURN.SZTLXPAS( SZT_PIDM,SZT_SEQNO,SZT_FECHA_INI)
                  VALUES ( ppidm,pseqno,SYSDATE );
                    NULL;

               EXCEPTION WHEN OTHERS THEN
               NULL;
               vsalida := 'error en insert--SZTLXPAS  '  || sqlerrm;
               END;

ELSIF Pcode IN ('CNLI','CNMA','CNMM', 'CNDO')  THEN --ESTO ES PARA CONECTA 02/03/2022
 vbandera := 'opcion CONECTA';

        ---vamos a buscar los meses y el codigo de detalle
              begin
                 select  SVRSVAD_ADDL_DATA_CDE code_dtl
                  into VCODE_DTLX
                    from saturn.svrsvpr v, saturn.SVRSVAD VA
                    where 1=1
                    and SVRSVPR_SRVC_CODE in (Pcode)
                       AND  SVRSVPR_PROTOCOL_SEQ_NO = pseqno
                       AND  SVRSVPR_PIDM   = PPIDM
                     --  AND SVRSVPR_SRVS_CODE = 'PA'
                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                      and va.SVRSVAD_ADDL_DATA_SEQ = '5' ---- codigo de detalle para saber los meses
                    -- AND SVRSVAD_ADDL_DATA_DESC  LIKE ('06/09/2021%')
                    --order by 1 desc
                    ;


              exception when others then
                  VCODE_DTLX := null;

              end;


            begin

                select distinct substr(ZSTPARA_PARAM_ID,1,1) meses
                 INTO  VMESES
                from ZSTPARA
                where ZSTPARA_MAPA_ID = 'COSTO_CONECTA'
                and  substr(ZSTPARA_PARAM_DESC,1,instr(ZSTPARA_PARAM_DESC,',',1)-1) = SUBSTR(VCODE_DTLX,3,2) --este es el que viene de la pregunta5
                and substr(ZSTPARA_PARAM_DESC,instr(ZSTPARA_PARAM_DESC,',',1)+1,5)  = Pcode
                ;

            exception when others then
            VMESES := 1;
            end;


          BEGIN

              VSALIDA :=  BANINST1.PKG_SERV_SIU.F_CONECTA ( PPIDM ,Pcode , PSEQNO  );

          EXCEPTION WHEN OTHERS THEN

            VSALIDA := 'eRROR EN F_CONECTA_trigger: '|| SQLERRM;

          END;
            -- INSERT INTO BANINST1.TWPASOW (VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6)
            --- VALUES ( :NEW.TBRACCD_PIDM ,vvcode , :NEW.TBRACCD_CROSSREF_NUMBER,VMESES,VCODE_DTLX, VSALIDA );


                   --- AQUI VA EL FLUJO DE UNICEF glovicx 08/03/2022
ELSIF   Pcode in ( 'UNLI','UNMA','UNMM' )    then
vbandera := 'opcion UNICEF';
                        --UNLI CERTIFICADO UNICEF LIC
                        --UNMA CERTIFICADO UNICEF MAE
                        --UNMM CERTIFICADO UNICEF MAST

          begin
         select  SVRSVAD_ADDL_DATA_CDE code_dtl, substr(VA.SVRSVAD_ADDL_DATA_DESC, 1, instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)-1) meses
            into VCODE_DTLX, VMESES
            from svrsvpr v,SVRSVAD VA
            where 1=1
             -- and SVRSVPR_SRVC_CODE in ('UNLI')
               AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
               AND  SVRSVPR_PIDM   = PPIDM
               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
               and va.SVRSVAD_ADDL_DATA_SEQ = '5' ;-- aqui estan los meses y el codigo OK que escogio el alumno



      exception when others then
          VCODE_DTLX := null;
          VMESES     := 0;
      end;


       ---aqui calcula la desc del codigo de detalle

             BEGIN
              SELECT DISTINCT TBBDETC_DESC
               INTO    VDESC_DTL
               FROM TBBDETC
               WHERE TBBDETC_DETAIL_CODE = VCODE_DTLX;
             EXCEPTION WHEN OTHERS THEN
                    VSALIDA:='Error :'||sqlerrm;
                     VCODE_DTLX:='';

             END;


    --  --dbms_output.PUT_LINE('ANTES DE  FLUJO unicef :: '||  VSALIDA||'-'||pcode||'-'|| VCODE_DTLX||'-'||VDESC_DTL||'-'|| VMESES);
             --  insert into twpasow (valor1, valor2, valor3, VALOR4, valor5, valor6  )
             -- values ('F_UNICEF:  ', ppidm  ,VCODE_DTLX ,null, pseqno,VSALIDA );


       VSALIDA :=  BANINST1.PKG_SERV_SIU.F_UNICEF ( PPIDM ,Pcode, VCODE_DTLX , VDESC_DTL ,Pseqno ,VMESES );

      --esta seccion alfinal aproduccion se puede quitar no tiene sentido es solo para pruebas



      ----dbms_output.PUT_LINE('TERMINA FLUJO unicef :: '||  VSALIDA||'-'||pcode||'-'|| VCODE_DTLX||'-'|| VMESES);
              -- insert into twpasow (valor1, valor2, valor3, VALOR4, valor5, valor6  )
              -- values ('F_UNICEF REGRESO DE FUNCION f_unicef:  ', :NEW.TBRACCD_PIDM ,VCODE_DTLX ,null, :NEW.TBRACCD_CROSSREF_NUMBER,VSALIDA );



ELSIF  Pcode in ( 'VOXY' )    then
vbandera := 'opcion VOXY';

       VSALIDA :=  BANINST1.PKG_SERV_SIU.F_VOXY ( PPIDM ,Pcode , PSEQNO   )   ;
       ----dbms_output.PUT_LINE('TERMINA FLUJO VOXY DESDE TRIGER TBRACCD :: '||PPIDM||'-'||PSEQNO||'-'|| VSALIDA  );


ELSIF Pcode in ( 'COLI' , 'COMA','COMM')    then
vbandera := 'opcion CURSERA';

       VSALIDA :=  BANINST1.PKG_SERV_SIU.F_CURSERA ( PPIDM ,Pcode , PSEQNO   )   ;
       ----dbms_output.PUT_LINE('TERMINA FLUJO COURSERA DESDE TRIGER TBRACCD :: '||PPIDM||'-'||PSEQNO||'-'|| VSALIDA  );
       
       
ELSE
   --NUEVA SECCION PARA LAS NUEVAS CERTIFICACIONES QUE ESTAN CONFIGURADAS EN SZTCTSIU GLOVICX 11.08.022
   FOR JUMP IN ( select distinct SZT_CODE_SERV AS CODE_SERV  from SZTCTSIU ) LOOP

    IF  PCODE = JUMP.CODE_SERV  THEN
        vbandera := 'opcion NEW_CURSO';

       VSALIDA :=  BANINST1.PKG_SERV_SIU.F_CURSO_SIU ( PPIDM ,Pcode , PSEQNO   )   ;
      -- --dbms_output.PUT_LINE('TERMINA FLUJO F_CURSOS GRAL SIU :: '||PPIDM||'-'||PSEQNO||'-'|| VSALIDA  );
    END IF;
    END LOOP;

end if;



--insert into twpasow( valor1, valor2, valor3, valor4, valor5)
--values ('P_CERTIFICA_AUTO_FINAL', PPIDM, PSEQNO, PCODE, vbandera  );


exception when others then
null;

  ----dbms_output.PUT_LINE('error al final gral :: '||  VSALIDA||'-'||pcode||'-'|| VCODE_DTLX||'-'|| VMESES);
end P_CERTIFICA_AUTO;


FUNCTION F_NIVE_AULA_DATOS  ( PPIDM NUMBER,  PCAMPUS VARCHAR2  )  Return  PKG_SERV_SIU.materia_hija2_type
IS

/*
este proceso es el que se usa para enviar las nivelaciones al aula virtual para que desde ahi las puedan comprar
SE AGREGA validacion de parametrizador sin moodle glovicx 30.06.022
-- SE AGREGA la funcionalidad para que solo presente las materias que se encuentran en el AVCU, glovicx 26.10.022
*/

TERMATERIAS   varchar2(20);
vsalida      varchar2(500);

  cuCursor SYS_REFCURSOR;




 begin



-- nuevo aqui buscamos el nuevo valor del periodo en shgrade glovicx 17/01/022

      begin
         select distinct ZSTPARA_PARAM_DESC
           INTO TERMATERIAS
        from ZSTPARA
        where 1=1
        and ZSTPARA_MAPA_ID = 'ESC_SHAGRD'
        and ZSTPARA_PARAM_ID = substr(F_GetSpridenID(PPIDM),1,2);
      exception when others then
          TERMATERIAS := null;

       end;


 ----este es el query general de donde viene tota la informacion se pasa directo al cursor
        open cuCursor for select datos2.matricula,datos2.nombre,datos2.materia,datos2.nombre_materia,datos2.estatus_alumno,datos2.campus,datos2.nivel,datos2.programa,datos2.materia_padre,
                                 datos2.materia_hija,datos2.estatus_materia,datos2.avcu
         ,case when datos2.materia in ( select ZSTPARA_PARAM_ID
                               FROM ZSTPARA
                                 WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION'
                                  AND ZSTPARA_PARAM_DESC  = datos2.CAMPUS) then
                  (select to_number(ZSTPARA_PARAM_VALOR)
                    FROM ZSTPARA
                    WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION'
                    and   ZSTPARA_PARAM_ID  = datos2.MATERIA
                    AND ZSTPARA_PARAM_DESC  = datos2.CAMPUS)
          
           WHEN (SELECT  PKG_SERV_SIU.F_NIVE_CERO (DATOS2.PIDM , 'NIVE', datos2.programa , datos2.materia  )
                    FROM DUAL)  = 'EXITO' then  0
          
          else
           (
            select distinct SZT_PRECIO
            from sztnipr
            where 1=1
            and SZT_NIVEL =  datos2.nivel
            and SZT_CAMPUS  =  DATOS2.CAMPUS
            and SZT_PRECIO > 0
            and ROUND(datos2.AVCU) between ( SZT_MINIMO ) and (SZT_MAXIMO )
            and substr(SZT_CODE,1,2) = substr(F_GetSpridenID(DATOS2.PIDM),1,2))
            
            
         end costo
                            from (
                            select distinct datos.matricula
                                    ,datos.nombre
                                    ,datos.materia MATERIA --||'|'||costo,
                                    ,rpad(cc.SCRSYLN_LONG_COURSE_TITLE,40,'-') NOMBRE_MATERIA
                                    ,(SELECT T.ESTATUS  FROM TZTPROG T
                                                 WHERE 1=1
                                                    AND  T.PIDM = DATOS.PIDM
                                                    AND T.PROGRAMA = datos.programa ) AS ESTATUS_ALUMNO
                                    ,DATOS.CAMPUS
                                    ,datos.nivel as nivel
                                    ,datos.programa
                                     ,SZTMACO_MATPADRE as materia_padre
                                     ,SZTMACO_MATHIJO  as materia_hija
                                    ,datos.estatus_materia
                                    ,(select distinct NVL(SZTHITA_AVANCE,1)
                                         from SZTHITA
                                         where 1=1
                                            and SZTHITA_PIDM = DATOS.PIDM
                                            AND  SZTHITA_LEVL = datos.nivel
                                            AND SZTHITA_STUDY  = DATOS.SP) AS AVCU
                                     --,'falta costo' as costo
                                    ,datos.sp
                                    ,DATOS.PIDM AS PIDM
                                    from (
                                            SELECT sp.spriden_id matricula
                                            , Sp.SPRIDEN_FIRST_NAME|| ' '|| replace(Sp.SPRIDEN_LAST_NAME,'/',' ') nombre
                                            , (qq.ssbsect_subj_code || qq.ssbsect_crse_numb) materia
                                            --( select M.SZTMACO_MATPADRE from sztmaco m where M.SZTMACO_MATHIJO = qq.SSBSECT_SUBJ_CODE || qq.SSBSECT_CRSE_NUMB) materia,
                                            , CASE
                                            WHEN qq.ssbsect_seq_numb IS NULL
                                            THEN
                                            SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                                            ELSE
                                            SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                                            END nombre_materia,
                                            so.SORLCUR_PROGRAM as programa
                                            ,SO.SORLCUR_PIDM as pidm
                                            ,SO.SORLCUR_LEVL_CODE AS NIVEL
                                            ,'1' FINAL
                                            ,cr.SFRSTCR_STSP_KEY_SEQUENCE as Sp
                                            ,SO.SORLCUR_CAMP_CODE  AS CAMPUS
                                            ,CR.SFRSTCR_RSTS_CODE estatus_materia
                                         FROM ssbsect qq, sfrstcr cr, shrgrde sh, sorlcur so, stvterm x, spriden sp
                                            ,(SELECT ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_ID, ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                                            FROM ZSTPARA
                                            WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION' ) cos
                                            WHERE 1=1
                                            AND cr.sfrstcr_pidm = PPIDM
                                            AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                                            AND cr.sfrstcr_crn = qq.ssbsect_crn
                                            AND sh.shrgrde_code = cr.SFRSTCR_GRDE_CODE
                                            and sh.SHRGRDE_LEVL_CODE = cr.SFRSTCR_LEVL_CODE
                                            AND sh.shrgrde_passed_ind = 'N'
                                            and cr.SFRSTCR_GRDE_CODE is not null
                                            AND so.SORLCUR_LMOD_CODE = 'LEARNER'
                                            AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS')
                                            AND sh.shrgrde_levl_code = so.SORLCUR_LEVL_CODE
                                            AND cr.sfrstcr_pidm = so.sorlcur_pidm
                                            And so.sorlcur_program in (  select distinct programa
                                                                            from tztprog
                                                                            where 1=1
                                                                            and pidm =  ppidm  )
                                            And cr.SFRSTCR_STSP_KEY_SEQUENCE = so.SORLCUR_KEY_SEQNO
                                            AND so.sorlcur_term_code = x.stvterm_code
                                            AND sp.spriden_change_ind IS NULL
                                            and cr.sfrstcr_pidm = SP.SPRIDEN_PIDM
                                            and cos.ZSTPARA_PARAM_DESC(+) = qq.ssbsect_subj_code || qq.ssbsect_crse_numb
                               --
                                 minus
                                            SELECT sp.spriden_id matricula
                                            , Sp.SPRIDEN_FIRST_NAME|| ' '|| replace(Sp.SPRIDEN_LAST_NAME,'/',' ') nombre
                                            ,qq.ssbsect_subj_code || qq.ssbsect_crse_numb materia
                                            , CASE
                                            WHEN qq.ssbsect_seq_numb IS NULL
                                            THEN
                                            SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                                            ELSE
                                            SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                                            END nombre_materia,
                                            so.SORLCUR_PROGRAM as programa
                                            ,SO.SORLCUR_PIDM as pidm
                                            ,SO.SORLCUR_LEVL_CODE AS NIVEL
                                            ,'2' FINAL
                                            ,cr.SFRSTCR_STSP_KEY_SEQUENCE as Sp
                                              ,SO.SORLCUR_CAMP_CODE  AS CAMPUS
                                             ,CR.SFRSTCR_RSTS_CODE estatus_materia
                                        FROM ssbsect qq, sfrstcr cr, sorlcur so, stvterm x, spriden sp
                                            ,(SELECT ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_ID, ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                                            FROM ZSTPARA
                                            WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION' ) cos
                                            WHERE 1=1
                                            AND cr.sfrstcr_pidm = PPIDM --fget_pidm('010075696')
                                            AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                                            AND cr.sfrstcr_crn = qq.ssbsect_crn
                                            and cr.SFRSTCR_GRDE_CODE is null
                                            and cr.SFRSTCR_RSTS_CODE = 'RE'
                                            AND so.SORLCUR_LMOD_CODE = 'LEARNER'
                                            AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS')
                                            AND cr.sfrstcr_pidm = so.sorlcur_pidm
                                            And so.sorlcur_program in (select distinct programa
                                                                            from tztprog
                                                                            where 1=1
                                                                            and pidm =  ppidm)
                                            AND so.sorlcur_term_code = x.stvterm_code
                                            AND sp.spriden_change_ind IS NULL
                                            and cr.sfrstcr_pidm = SP.SPRIDEN_PIDM
                                            And cr.SFRSTCR_STSP_KEY_SEQUENCE = so.SORLCUR_KEY_SEQNO
                                            and cos.ZSTPARA_PARAM_DESC(+) = qq.ssbsect_subj_code || qq.ssbsect_crse_numb
                                 ) datos
                                           , SCRSYLN cc,sztmaco ko
                                            where 1=1
                                            and SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB = datos.materia
                                            and SZTMACO_MATHIJO  = datos.materia
                                           -- and SZTMACO_CAMP_CODE = NVL(datos.campus,SZTMACO_CAMP_CODE)
                                            and SZTMACO_LEVL_CODE = datos.nivel
                                            --and SZTMACO_PROGRAM = nvl(datos.programa,SZTMACO_PROGRAM)
                                            AND NOT EXISTS
                                            (SELECT 1
                                            FROM SVRSVPR p, SVRSVAD h
                                            WHERE p.SVRSVPR_SRVC_CODE = 'NIVE'
                                            AND P.SVRSVPR_PIDM = PPIDM --fget_pidm('010075696')
                                            AND p.SVRSVPR_SRVS_CODE  in ('AC')--se quito la validacion de "PA" a peticion de Fernando el dia 05/12/2019
                                            AND h.SVRSVAD_PROTOCOL_SEQ_NO = p.SVRSVPR_PROTOCOL_SEQ_NO
                                            and h.SVRSVAD_ADDL_DATA_CDE = datos.materia)
                                            and datos.materia NOT in ( select SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB
                                                            FROM ssbsect qq, sfrstcr cr, shrgrde SH
                                                            WHERE 1=1
                                                            AND cr.sfrstcr_pidm = PPIDM --fget_pidm('010075696')
                                                            AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                                                            AND cr.sfrstcr_crn = qq.ssbsect_crn
                                                             and  SHRGRDE_TERM_CODE_EFFECTIVE   = TERMATERIAS
                                                            and ( cr.SFRSTCR_GRDE_CODE in ('6.0','7.0','8.0','9.0','10.0')
                                                            or cr.SFRSTCR_GRDE_CODE is null )
                                                            AND CR.SFRSTCR_GRDE_CODE = SH.SHRGRDE_CODE
                                                            AND CR.SFRSTCR_LEVL_CODE = SH.SHRGRDE_LEVL_CODE
                                                            AND shrgrde_passed_ind = 'Y' ---------ESTO DIVIDE LAS CALIFICACIONES EN PASADAS Y REPROBADAS PARA LI Y MA.MS
                                                            and cr.sfrstcr_term_code = (select max(cr.sfrstcr_term_code ) from sfrstcr c2 where cr.sfrstcr_pidm = c2.sfrstcr_pidm ))
                                            And (DATOS.PIDM, datos.materia ) not in (select a.SFRSTCR_PIDM, b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB
                                                                                                                        from sfrstcr a, ssbsect b
                                                                                                                        Where  a.SFRSTCR_TERM_CODE =  b.SSBSECT_TERM_CODE
                                                                                                                        And a.SFRSTCR_CRN = b.SSBSECT_CRN
                                                                                                                        And a.SFRSTCR_RSTS_CODE = 'RE'
                                                                                                                        and ( a.SFRSTCR_GRDE_CODE in (select SHRGRDE_CODE
                                                                                                                                                            from SHRGRDE
                                                                                                                                                            Where SHRGRDE_LEVL_CODE = a.SFRSTCR_LEVL_CODE
                                                                                                                                                            and  SHRGRDE_TERM_CODE_EFFECTIVE   = TERMATERIAS
                                                                                                                                                            And SHRGRDE_PASSED_IND ='Y')
                                                                                                                             or a.SFRSTCR_GRDE_CODE is null ))
                                             and datos.materia not in (select ZSTPARA_PARAM_VALOR
                                                                                from zstpara z
                                                                                where 1=1
                                                                                and Z.ZSTPARA_MAPA_ID  = 'SIN_MAT_MOODLE' )
                              ORDER BY 1,6
                              ) datos2
                              ;

RETURN (cuCursor);

exception when others then
VSALIDA := SQLERRM;

--dbms_output.put_line('ERROR GRAL FUNCION F_NIVE_AULA_DATOS: '|| VSALIDA);
--return VSALIDA;

END F_NIVE_AULA_DATOS;


FUNCTION F_ACC_GIFT  (PPIDM IN NUMBER, PCODE IN VARCHAR2, pprograma IN varchar2 ) RETURN VARCHAR2
IS
---  ESTA FUNCIÓN SE REALIZO PARA EL PROYECTO DE REGALAR UN COTE O CAPS A LOS ALUMNOS QUE COMPREN
---- UNA COLF SI REGRESA EXITO ENTONCES SI CUMPLE LOS REQUISITOS PARA TOMAR EL BENEFICIO GLOVICX 26.07.022
--modificación si compra la COLF no es necesario validar la etiqueta
-- modificación II si compra el paquete de venta entonces si es obligatoria la etiqueta glovicx 25.08.022

--  ESTA FUNCIÓN SE EJECUTA DE MODO INTERNO Y TAMBIEN DESDE PYTHON, SI REGRESA EXITO ENTONCES, SE LE PONE COSTO CERO EN EL AUTOSERV. GLOVICX 07/05/2025


vegresado varchar2(1):= 'N';
vpago1    varchar(1):='N';
vpago2    varchar(1):='N';
VBNFTS    varchar(1):='N';
VSALIDA   VARCHAR2(200):='EXITO';
p_adid_code   varchar(15);
vl_existe   varchar(1):='N';
vval_benef   varchar(1):='N';
vsaldo  NUMBER:= 0;
VAVANCE  NUMBER:= 0;
VNIVEL     varchar(3);
vcampus    varchar(3);
vestatus   varchar(3);
vcote      varchar(1):='N';
vcaps      varchar(1):='N';
vingreso    varchar(3);

begin

   --- se cambia por este para DOC_COST_0
      begin
          select 'Y'
            into vval_benef
            from zstpara
             where 1=1
               and ZSTPARA_MAPA_ID   = 'DOC_COST_0'
               and ZSTPARA_PARAM_VALOR  = pcode;

      exception when others then
       vval_benef := 'N';
      end;
---
-- primero buscamos nivel y campus, estatus
     begin
     
        select distinct  T.NIVEL, T.CAMPUS, t.estatus,  t.TIPO_INGRESO
           into  VNIVEL, vcampus, vestatus, vingreso
            from tztprog t
                where 1=1
                  and T.ESTATUS not in ('CV','CP' )
                  and t.pidm = PPIDM
                  and t.programa    = pprograma
                  and t.SP = ( select max(t2.SP)   
                                  from  tztprog t2
                                   where 1=1
                                     and t.pidm    = t2.pidm 
                                     and t2.programa  =  pprograma
                                     ); 
 
     exception when others then
          VNIVEL   := null;
          vcampus  := null;
          vestatus := null;
          vingreso := null;
       dbms_output.put_line('error en datos TZTPROG:  '||sqlerrm  );
      end;

    --- buscamos el avance--
         BEGIN
          
             VAVANCE :=0;
             
                   SELECT ROUND(nvl(SZTHITA_AVANCE,0))
                      INTO VAVANCE
                        FROM SZTHITA ZT
                        WHERE 1=1
                        and   ZT.SZTHITA_PIDM   = PPIDM
                        AND   ZT.SZTHITA_LEVL  = VNIVEL
                        AND   ZT.SZTHITA_PROG   = PPROGRAMA  ;
                        
                       dbms_output.PUT_LINE('SALIDA AVANCE HITA  '|| VAVANCE);
          EXCEPTION WHEN OTHERS THEN
              
                        BEGIN
                           SELECT ROUND(BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 ( PPIDM, PPROGRAMA ))
                                  INTO VAVANCE
                             FROM DUAL;

                          --   --dbms_output.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
                          EXCEPTION WHEN OTHERS THEN
                           VAVANCE :=0;
                          END;
          END;
    
   IF VAVANCE > 100 then
     VAVANCE := 100;
   end if;


  IF vval_benef = 'Y' THEN
    -- 1ero se valida el estatus del agresado
    /*
     begin
         select 'Y'
              into vegresado
            from tztprog
            where 1=1
            and pidm = ppidm
            and PROGRAMA = pprograma
            and ESTATUS = 'EG';
      exception when others then
        vegresado := 'N';
        VSALIDA    := 'N';
      end;
      */
       -- --dbms_output.put_line(' valicacion EG: 1: '|| vegresado  );

--2do valida si ya tiene pagado un accesorio de COLF ya sea comprado o en pakete
 --2a.- compardo
    begin
        select 'Y'
           into vpago1
            from svrsvpr v,SVRSVAD VA
            where 1=1
            and V.SVRSVPR_SRVC_CODE IN ('COLF')
            AND  V.SVRSVPR_PIDM    = PPIDM
            and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
            and va.SVRSVAD_ADDL_DATA_SEQ = '1'
             AND VA.SVRSVAD_ADDL_DATA_CDE = PPROGRAMA
             and V.SVRSVPR_SRVS_CODE in ( 'PA', 'CL');
     exception when others then
         vpago1  := 'N';
         VSALIDA  := 'N';
    end;
      
      dbms_output.put_line(' despues de validar COLF  '|| vpago1 );

-- 2a  QUE ESTE PGADO A TRAVEZ DEL UN PAKETE DE VENTAS AL INICIO
   /*
     begin

        select 'Y'
          INTO vpago2
        from tbraccd
        where 1=1
        and tbraccd_pidm = ppidm
            and substr(TBRACCD_DETAIL_CODE,3,2) in (select distinct substr(ZSTPARA_PARAM_VALOR,3,2)
                                                    from zstpara
                                                    where 1=1
                                                        and ZSTPARA_MAPA_ID = 'COLF_CONS_QR')
        and TBRACCD_BALANCE = 0;

    exception when others then
         vpago2  := 'N';
         VSALIDA  := 'N';
    end;
        ----dbms_output.put_line(' valicacion pagoB: 2: '|| vpago2  );
    */

    --validamos que ese alumno tenga su etiqueta en GORADID--TIIN--
         Begin
            Select 'Y'
                Into vl_existe
                from GENERAL.GORADID
            Where GORADID_PIDM = PPIDM
            And GORADID_ADID_CODE in (select distinct ZSTPARA_PARAM_ID 
                                         from zstpara
                                        where 1=1
                                           and ZSTPARA_MAPA_ID   =  'ETIQUETAS_COLF');
         Exception When Others then
                vl_existe :='N';
                VSALIDA  := 'N';
                dbms_output.put_line(' error en NO tiene etiquta: 3: '|| vl_existe  );
        End;


      dbms_output.put_line(' valicacion etiquta: 3: '|| vl_existe  );
 --3ro-- hay que validar que no se haya consedido gratis  UNO de los  accesorios antes
          -- CUANDO SE INSERTA EL BENEFIO SE LE AGREGA ESTA COLUMNA PARA SABER QUE YA TOMO UNOS DE LOS BENEFIOS
     BEGIN

            select 'Y'
                into VBNFTS
            from SVRSVPR  v
            WHERE 1=1
            and   SVRSVPR_PIDM = PPIDM
            and   SVRSVPR_SRVC_CODE IN (select ZSTPARA_PARAM_VALOR
                                        from zstpara
                                         where 1=1
                                           and ZSTPARA_MAPA_ID   = 'DOC_COST_0')
            and   SVRSVPR_STEP_COMMENT = 'BNFTS'; -- CLAVE DISTINTIVA PARA SABER QUE YA TOMO EL BENEFICIO

     exception when others then
         VBNFTS   := 'N';
         VSALIDA  := 'EXITO';
     end;
     
      dbms_output.put_line(' despues de validar sasvpr  '|| VBNFTS );

        --4TA NUEVA REGLA QUE NO TENGA UN ADEODO MAS DE 200 PESOS  GLOVICX 20.01.2025 HAY QUE BUSCAR SI ENTRA EN UN AGRUPADOR
     
       begin
            vsaldo:= NVL(BANINST1.PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia_Titulo (PPIDM),0);

        exception when others then
          vsaldo := 0;
        end;
   
     -----nuevas reglas  glovicx 05'05'2025
   IF PCODE = 'COTE'  THEN 
     dbms_output.put_line(' valicacion estoy en COTE: '||  VSALIDA  );
    --   Para los alumnos de LATAM LI, solo deben tener estatus de EG, con el 100% de avance curricular.
      IF   Vestatus = 'EG' and VAVANCE >= 100  then
         
        vcote := 'Y';
        
      end if;
 
   ELSIF   PCODE = 'CAPS' AND vnivel = 'LI'  THEN 
     
      IF   (Vestatus = 'MA' and VAVANCE >= 70)  OR (Vestatus = 'EG' and VAVANCE >= 100)  then
         
        vcaps := 'Y';
        
      end if;
 
       dbms_output.put_line(' valicacion estoy en CAPS:  '|| vcaps||'-'|| VSALIDA  );
   
   END IF;
   
    dbms_output.put_line(' valicacion finales COTE:  '||  VSALIDA ||'-'|| vcote ||'-'|| vpago1||'-'|| vl_existe ||'-'|| VBNFTS ||'-'|| VSALDO  );
    dbms_output.put_line(' valicacion finales CAPS:  '||  VSALIDA ||'-'|| vcaps ||'-'|| vpago1||'-'|| vl_existe ||'-'|| VBNFTS ||'-'|| VSALDO  );
   
   IF VSALIDA = 'EXITO' AND vcote ='Y' and vpago1='Y' and vl_existe='Y' and VBNFTS='N' AND VSALDO <= 200 THEN -- cuando la COTE

       RETURN VSALIDA;
      
   ELSIF VSALIDA = 'EXITO' AND vcaps='Y' and vpago1='Y'  and vl_existe='Y' and VBNFTS='N' AND VSALDO <= 200  THEN -- CAMINO 2 compra CAPS
        
        RETURN VSALIDA;

    ELSE

        RETURN 'NO CUMPLE';

    END IF;

   ELSE

  RETURN 'NO CUMPLE';

  end if;  -- por si entra otro accesorio que no sean los mencionados

exception when others then
 VSALIDA    := 'ERROR GRAL EN F_ACC_GIFT:: '|| SQLERRM;

 RETURN VSALIDA;


end F_ACC_GIFT;


FUNCTION F_CERTF_MENS  (PPIDM IN NUMBER, PCODE IN VARCHAR2, pprograma IN varchar2 ) RETURN PKG_SERV_SIU.cur_certifica_type
IS

VSALIDA  VARCHAR2(300);
cur_certifica  SYS_REFCURSOR;
VAVANCE      number:=0;


BEGIN
-- este curso regresa todas las nuevas certificaciones que estan en la tabla de SZTCTSIU, con modalidad y cargo
-- este se ocupa para los combos de pago, en siu.

--- se obtiene el av para los rangos de COFU  regla fer 21.02.2023 glovicx
--  se agreaga nueva regla para COFU según Betzy glovicx 29.03.2023

            Begin
                  SELECT BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 (PPIDM, pprograma)
                    INTO VAVANCE
                    FROM DUAL;
               --   --dbms_output.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VAVANCE := 0;
               END;

----dbms_output.put_line( 'salida de avance alumno '|| VAVANCE ||'-'|| PCODE);

IF PCODE = 'COFU' then
----dbms_output.put_line( 'ENTRO EN COFU '|| VAVANCE ||'-'|| PCODE);
open cur_certifica  for
select distinct ct.SZT_CODE_SERV, ct.SZT_CODTLE, ct.SZT_MODALIDAD, ct.SZT_DIFERIDO,CT.SZT_MESES
                       -- ,substr(z.ZSTPARA_PARAM_ID,1,2),substr(z.ZSTPARA_PARAM_ID,4,2)
                        from SATURN.SZTCTSIU ct, ZSTPARA z
                        where 1=1
                        and  substr(CT.SZT_CODTLE,1,2) =  SUBSTR(F_GetSpridenID(Ppidm),1,2)
                        and ct.SZT_CODE_SERV = PCODE
                        and z.ZSTPARA_MAPA_ID = 'COFU_DIFERIDOS'
                        and CT.SZT_MESES =  z.ZSTPARA_PARAM_VALOR
                        and ( round(VAVANCE) between nvl(substr(z.ZSTPARA_PARAM_ID,1,2),0) and nvl(substr(z.ZSTPARA_PARAM_ID,4,2),0)
                                   );

ELSE
-- AQUI CAEN TODOS LOS DEMAS

open cur_certifica  for
                        select ct.SZT_CODE_SERV, ct.SZT_CODTLE, ct.SZT_MODALIDAD, ct.SZT_DIFERIDO,CT.SZT_MESES
                        from SATURN.SZTCTSIU ct
                        where 1=1
                        and  substr(CT.SZT_CODTLE,1,2) =  SUBSTR(F_GetSpridenID(Ppidm),1,2)
                        and ct.SZT_CODE_SERV = PCODE
                        and ( round(VAVANCE) between nvl(substr(ct.SZT_RANGO_AVCU,1,2),0) and nvl(substr(ct.SZT_RANGO_AVCU,4,2),0)
                      or  0 between nvl(substr(ct.SZT_RANGO_AVCU,1,2),0) and nvl(substr(ct.SZT_RANGO_AVCU,4,2),0) );

END IF;

RETURN cur_certifica;

EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;


END F_CERTF_MENS;

FUNCTION F_CURSO_SIU (PPIDM IN NUMBER, PCODE IN VARCHAR2, PSEQNO IN NUMBER   ) RETURN VARCHAR2
IS

-- proceso que contiene la funcionalidad de las nuevas certificaciones de la tabla sztgece glovicx 16.08.022
-- se hizo el ajuste en el valor de número de pagos para LATAM  glovicx 28.02.2023
-- se hace ajuste para BOOTCAMp el cambio en el num de las preguntas glovicx 19.05.2023
-- LIBERACION DE CAMBIO NUM PREGUNTAS UCAM Y BOOTCAMP GLOVICX 10.08.2023
-- AJUSTE PARA la pantalla de promociones se agregan 3 nuevas preguntas LIBERADO 12.03.2024
-- AJUSTE  etiquetas de cambidge y duolingo glovicx 05.10.2023
-- ajuste para estatus de hackthon   glovicx 26.03.2025

P_ADID_CODE   VARCHAR2(6);
P_ADID_ID     VARCHAR2(12);
vetiqueta     varchar2(50);
vsalida       varchar2(300):= 'EXITO';
vsal_dif      varchar2(200);
VNIVEL       varchar2(20);
vl_existe     NUMBER ;
vcve_dtl_papa    varchar2(6);
VMESES          varchar2(6);
VDIFERIDO       varchar2(6);
vtipo_serv   varchar2(20);
VVALIDA_MAIL  VARCHAR2(1):= 'N';
VAL_NUM_MES   VARCHAR2(1):=0;
V_PROMO        VARCHAR2(10):=0;
VFECHA_INI     VARCHAR2(12);
Vsyncro            number:= 1;
v_mail            varchar2(50);
vtipo_alianza   varchar2(20);
VPREG10         NUMBER:=0;
VPREG7          NUMBER:=0;
vporig           number:=0;
vpdest           number:=0;
vcambia        varchar2(1):= 'N';
V_montodesc   varchar2(20);
V_numdesc   varchar2(20);
V_cupon      varchar2(20);
VESPECIALES   VARCHAR2(1):='N';
V_FREC_PAGO  varchar2(30);
vprograma    varchar2(20);

vcampus     varchar2(4);
vestatus    varchar2(4):= 'CL';  -- hktn glovicx 26.03.2025

BEGIN
          -- se obtienen los valores de campus, nivel prog para enviarlos en los paramatros inserta COTA glovicx 04.11.2024
    
     begin

          select distinct t.programa,t.nivel, t.campus
                   INTO vprograma , vnivel, vcampus
           from tztprog t
              where 1=1
                  and  t.pidm = PPIDM
                  and  t.programa = (select DISTINCT VA.SVRSVAD_ADDL_DATA_CDE
                                      FROM svrsvpr v, SVRSVAD VA
                                        where 1=1
                                          and VA.SVRSVAD_ADDL_DATA_SEQ = 1
                                          and V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                          anD V.SVRSVPR_PIDM    =  PPIDM
                                          AND v.SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO);


                ----dbms_output.PUT_LINE('despues de nivel SEJM:'||vprograma||'-'||  vnivel );
      EXCEPTION WHEN OTHERS THEN

                begin
                   select s1.SORLCUR_PROGRAM, s1.SORLCUR_LEVL_CODE, s1.SORLCUR_CAMP_CODE
                      INTO vprograma , vnivel, vcampus
                    from sorlcur s1
                   where 1=1
                   and s1.sorlcur_pidm = PPIDM
                   and S1.SORLCUR_PROGRAM  = (select DISTINCT VA.SVRSVAD_ADDL_DATA_CDE
                                              FROM svrsvpr v, SVRSVAD VA
                                                where 1=1
                                                  and VA.SVRSVAD_ADDL_DATA_SEQ = 1
                                                  and V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                                  anD V.SVRSVPR_PIDM    =  PPIDM
                                                  AND v.SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO)
                   and s1.SORLCUR_SEQNO = (select max (s2.SORLCUR_SEQNO)  from sorlcur s2
                                            where 1=1
                                              and s1.sorlcur_pidm = s2.sorlcur_pidm 
                                               and S1.SORLCUR_PROGRAM =  S2.SORLCUR_PROGRAM  );


                EXCEPTION WHEN OTHERS THEN
                    vprograma := NULL;
                    vnivel    := null;
                    vcampus   := null;
                    

                 end;


      END;



          --VALIDA SI EXISTE LAS ETIQUETAS EN GORADID
    --REGLA DE FERNANDO HAY QU EVALIDAR si es un accesorio de sincronia en sztgece 04.11.022
    --- sacamos el tipo de alianza para ver si es plataforma, idiosmas o certificados glovicx 28.11.2022
      BEGIN
         select distinct g.SZT_TIPO_ALIANZA,SZT_SYN_AV
           INTO vtipo_serv, Vsyncro
        from saturn.SZTGECE g
             where 1=1
              AND G.SZT_CODE_SERV = PCODE;
      Exception  When Others then
      vtipo_serv := NULL ;
      Vsyncro   := 1;
      vsalida := 'No se encontro configuración en SZTGECE:::';
     END;

 --  DBMS_OUTPUT.PUT_LINE('INICIO F_CURSO_SIU: '|| PPIDM||'-'||PCODE||'-'|| vtipo_serv );
     ----- validamos si hay que cambiar numeros de preguntas
     begin
         select 'Y', substr(ZSTPARA_PARAM_DESC,5) as orig, substr(ZSTPARA_PARAM_VALOR,5) as dest
           INTO vcambia, vporig, vpdest
            from ZSTPARA
            where 1=1
            and ZSTPARA_MAPA_ID = 'CAMBIA_PREGUNTA'
            and ZSTPARA_PARAM_ID = pcode ;

      Exception  When Others then
      vcambia :='N' ;
      vporig :='' ;
      vpdest :='' ;
      --dbms_output.put_line( 'No se encontro configuración en cambio de pregunta:::');
     
     
     end;
   
   

       IF vcambia = 'Y' then --- PARA ESTE CASO en especifico se tuvo que invertir el orden de las preguntas x que en siu hay un proceso
                                            -- que los necesita en ese orden regla betzy 19.05.023
            VPREG10 :=vporig;
            VPREG7   := vpdest;
            
        ELSE
         
            IF PCODE = 'DPLO' THEN
            VPREG10 := 10;
            END IF;
            
            
         --dbms_output.put_line( 'dentro de cambio de pregunta:::'||VPREG10 ||'-'||VPREG7    );
        END IF;
        

      IF vtipo_serv = 'Plataformas'  THEN  -- AQUIE PLATAFORMA

        -----BUSCAMOS PARA EL CASO DE UCAMP LA etiqueta que esta gusraddo en las preguntas, regla fernando

              begin
                select distinct  SVRSVAD_ADDL_DATA_CDE
                     INTO P_ADID_CODE
                    from svrsvpr v,SVRSVAD VA
                    where 1=1
                     ANd SVRSVPR_SRVC_CODE = PCODE
                     AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                     anD  SVRSVPR_PIDM    =  PPIDM
                     and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                     and va.SVRSVAD_ADDL_DATA_SEQ = VPREG10 ; --'10';


                 Exception  When Others then
                P_ADID_CODE := NULL;

             end;

      elsif vtipo_serv = 'Idioma'  then  --- para idiomas sacamos la etiqueta de la pregunta 11 duoling y cambr glovicx 05.10.2023
            
           begin
                select distinct  SVRSVAD_ADDL_DATA_CDE
                     INTO P_ADID_CODE
                    from svrsvpr v,SVRSVAD VA
                    where 1=1
                     ANd SVRSVPR_SRVC_CODE = PCODE
                     AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                     anD  SVRSVPR_PIDM    =  PPIDM
                     and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                     and va.SVRSVAD_ADDL_DATA_SEQ = 11 ; --'10';


                 Exception  When Others then
                P_ADID_CODE := NULL;
               -- dbms_output.PUT_LINE('Error en etiquetas idiomas '|| sqlerrm );
             end;


      ELSE  
           --  SE SACA LA ETIQUETA DE BLEN DE LA PREGUNTA 10 HAY QUE VER SI SE PUEDE HOMOGENIZAR
           -- PARA TODAS LAS CERTIFICACIONES EN ESA PREGUTA GLOVICX 09.02.2024
           ----- para las certificaciones de DPLO glovicx 15.04.2024
           IF PCODE = 'BLEN'  OR  PCODE = 'DPLO'  THEN
           
            BEGIN
           
             select DISTINCT VA.SVRSVAD_ADDL_DATA_CDE
               INTO P_ADID_CODE
              FROM svrsvpr v, SVRSVAD VA
               where 1=1
                and V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                anD V.SVRSVPR_PIDM    =  PPIDM
                AND v.SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
               and VA.SVRSVAD_ADDL_DATA_SEQ = VPREG10;  -- PREGUNTA  de la etiqueta.
           
            Exception  When Others then
                  P_ADID_CODE := '';
                  vsalida:='Error calcula etiqueta 2 '||sqlerrm;
              -- dbms_output.PUT_LINE('ETIQUETA 1Xa '|| PPIDM||'-'||PCODE||'-'||PSEQNO||'-'|| VPREG10 );
            END;
           
           END IF;
           
          
         
        ----dbms_output.PUT_LINE('INICIO 1X '|| PPIDM||'-'||PCODE||'-'||vtipo_serv||'-'|| P_ADID_CODE );

        END IF;
        
        IF P_ADID_CODE IS NULL THEN 
      
          -- PRIMERO RECUPERAMOS EL VALOR DE LA ETIQUETA QUE YA ESTA CONFIGURADA
             BEGIN
                    select DISTINCT G.SZT_ETIQUETA
                      INTO P_ADID_CODE
                    from sztgece G
                    WHERE 1=1
                    AND G.SZT_CODE_SERV = PCODE
                    and g.SZT_NIVEL  =  vnivel
                    and g.SZT_TIPO_ALIANZA = vtipo_serv  ;

             Exception  When Others then
              P_ADID_CODE := '';
               vsalida:='Error calcula etiqueta 3'||sqlerrm;

             END;

       END IF;
----dbms_output.PUT_LINE('INICIO 2X '|| PPIDM||'-'||PCODE||'-'|| P_ADID_CODE );

--  se buscan los tres columnas que pidio fernando para tztcota PARA PLATAFORMAS Y CERTIFICACIONES ES IGUAL
        ---- SE DEBE DE PONER UN IF PARA LAS ACCESORIOS QUE TIENEN EL DATO DE MES A LA MITAD DE LA CADENA Y OTRO PARA LOS QUE LO TIENEN EL NICIO
     BEGIN  ---- TODOS LOS QUE TIENEN 97,98,99 SON X SEMESTRES O ANUALES ETC LLEVAN NUEVO MODELO DE RECUPERACION GLOVICX 14.08.2023
                    
            SELECT DISTINCT  'Y'
             INTO VESPECIALES
            FROM  SZTCTSIU G
            WHERE 1=1
            AND G.SZT_MESES IN (97,98,99)
            AND G.SZT_CODE_SERV = PCODE;
     
     
     EXCEPTION WHEN OTHERS THEN
       VESPECIALES := 'N';
     END;

--DBMS_OUTPUT.PUT_LINE('ES ESPOECIALES :  '|| VESPECIALES );

      IF VESPECIALES = 'Y'  THEN

             begin
               select distinct g.SZT_MESES, g.SZT_DIFERIDO,G.SZT_CODTLE,
                   substr(VA.SVRSVAD_ADDL_DATA_DESC,1,instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)-1) as frec
                    INTO   VMESES, VDIFERIDO,vcve_dtl_papa, V_FREC_PAGO
                  from svrsvpr v,SVRSVAD VA, SZTCTSIU G
                  where 1=1
                    and v.SVRSVPR_SRVC_CODE = Pcode
                    AND v.SVRSVPR_PROTOCOL_SEQ_NO = Pseqno
                    and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                    AND  va.SVRSVAD_ADDL_DATA_SEQ = 5
                    AND  v.SVRSVPR_PIDM    = Ppidm
                    and  substr(g.SZT_CODTLE,1,2) =  SUBSTR(F_GetSpridenID(Ppidm),1,2)
                    and  v.SVRSVPR_SRVC_CODE  = g.SZT_CODE_SERV
                    and  TRIM(substr(VA.SVRSVAD_ADDL_DATA_DESC, instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)+1, 3)) = G.SZT_MESES;

                 Exception  When Others then

             VMESES  := 01;
             VDIFERIDO  := 0;
              vsalida:='Error en diferido 1'||sqlerrm;
                --dbms_output.PUT_LINE('error en los meses y diferidos 3X '|| PPIDM||'-'||VMESES||'-'|| VDIFERIDO );
             end;
             
     
       ELSE
          
  
        --- si es Idiomas lleva una nueva busqueda
        -- IF vtipo_serv = 'Idioma' or vtipo_serv ='Certificación'  or vtipo_serv ='Otros'  then
         IF vtipo_serv IN  ('Idioma','Certificación','Otros', 'Plataformas' )  then  --glovicx 03.09.24 ajuste
         begin 
          select distinct g.SZT_MESES, g.SZT_DIFERIDO
                INTO   VMESES, VDIFERIDO
            from svrsvpr v,SVRSVAD VA, SZTCTSIU G
             where 1=1
                    and v.SVRSVPR_SRVC_CODE = Pcode
                    AND v.SVRSVPR_PROTOCOL_SEQ_NO = Pseqno
                    and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                    AND  va.SVRSVAD_ADDL_DATA_SEQ = 5
                    AND  v.SVRSVPR_PIDM    = PPIDM
                    and  substr(g.SZT_CODTLE,1,2)     =   SUBSTR (F_GETSPRIDENID (PPIDM), 1, 2)  --- ajuste latam 28.02.2023
                    and  v.SVRSVPR_SRVC_CODE  = g.SZT_CODE_SERV
                    and TRIM(substr(VA.SVRSVAD_ADDL_DATA_DESC,(instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)+1),4))  = G.SZT_MESES  ; --- esto es para idiomas
                    
          Exception  When Others then

         VMESES  := 01;
         VDIFERIDO  := 0;
          vsalida:='Error en diferido 2'||sqlerrm;
            --dbms_output.PUT_LINE('error en los meses y diferidos 3XxZ-- '|| PPIDM||'-'||VMESES||'-'|| VDIFERIDO );
         end;
         
        -- dbms_output.PUT_LINE('SALIDA  meses y diferidos 3XxZ-- '|| PPIDM||'.'||Pcode||'-'||Pseqno ||'-'||VMESES||'-'|| VDIFERIDO );
     ELSE
                    BEGIN
                        select distinct g.SZT_MESES, g.SZT_DIFERIDO
                             INTO   VMESES, VDIFERIDO
                            from svrsvpr v,SVRSVAD VA, SZTCTSIU G
                                where 1=1
                                    and v.SVRSVPR_SRVC_CODE = PCODE
                                    AND v.SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                                    and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                    AND  va.SVRSVAD_ADDL_DATA_SEQ = 5
                                    AND  v.SVRSVPR_PIDM    = PPIDM
                                    and  substr(g.SZT_CODTLE,1,2)     =   SUBSTR (F_GETSPRIDENID (PPIDM), 1, 2)  --- ajuste latam 28.02.2023
                                    and  v.SVRSVPR_SRVC_CODE  = g.SZT_CODE_SERV
                                      and  substr(VA.SVRSVAD_ADDL_DATA_DESC,1,(instr(VA.SVRSVAD_ADDL_DATA_DESC,'|',1)-1)) = G.SZT_MESES;
                     Exception  When Others then

                             VMESES  := 01;
                             VDIFERIDO  := 0;
                             vsalida:='Error en diferido 3'||sqlerrm;
                               -- dbms_output.PUT_LINE('error en los meses y diferidos 3XZZQ '|| PPIDM||'-'||VMESES||'-'|| VDIFERIDO );
                    end;
          
     
     
        END IF;
     
  
  
       END IF;-- TERMINA VESPECIALES 
  

    --dbms_output.PUT_LINE('INICIO 3X '|| PPIDM||'-'||VMESES||'-'|| VDIFERIDO );
      begin
          select SVRSVAD_ADDL_DATA_DESC
                INTO VFECHA_INI
            from svrsvpr v,SVRSVAD VA
              where 1=1
                 AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                 anD  SVRSVPR_PIDM    = PPIDM
                 and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                 and va.SVRSVAD_ADDL_DATA_SEQ = VPREG7 -- '7'
                order by 1 desc
                ;

         Exception  When Others then

     VFECHA_INI  := '01/01/1900';


     end;

      IF PCODE = 'UCAM'  THEN  --AQUI lo que hace es asigna la fecha de inicio a la etiqueta regla FER 04.11.022

      P_ADID_ID := VFECHA_INI;
      ELSE

      P_ADID_ID := P_ADID_CODE;

      END IF;

  ----dbms_output.PUT_LINE('INICIO 4X '|| PPIDM||'-'||P_ADID_ID||'-'|| VFECHA_INI );

      --INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5 )
      -- VALUES('PASO INICIO DE etiqueta certificados NO2:' ,PPIDM, pseqno,P_ADID_ID, vtipo_serv);


           -- SE INSERTA LA ETIQUETA GORADID
         -- primero validamos que ese alumno tenga su etiqueta en GORADID--TIIN-- hay que vincular con un poarametrizador code serv vs etiqueta vs code detalle
                 Begin
                        Select count(1)
                            Into vl_existe
                            from GENERAL.GORADID
                        Where GORADID_PIDM = PPIDM
                        And GORADID_ADID_CODE  = p_adid_code;
                 Exception
                    When Others then
                        vl_existe :=0;
                End;


                If vl_existe =0 then

                         begin
                            insert into GORADID values(PPIDM,P_ADID_ID, P_ADID_CODE, 'WWW_QRDI', sysdate, PCODE,null, 0,null);
                         Exception
                         When others then
                         vsalida:='Error al insertar Etiqueta'||sqlerrm;
                         end;

                 ELSIF vl_existe =1 AND  PCODE = 'HKTN'  THEN  -- PARA EL PROCESO DE HACKATHON SE HACE EL UPDATE DE LA ETIQUETA A LA FECHA DE COMPRA
                 NULL;  --  aqui va  update..
                   
                   begin
                      UPDATE GORADID G3
                        SET G3.GORADID_ACTIVITY_DATE  = sysdate,
                            G3.GORADID_DATA_ORIGIN    = 'WWW_SIU'
                        where 1=1
                         and G3.GORADID_PIDM         = ppidm
                         and G3.GORADID_ADID_CODE    = 'HKTN' ;
                   
                    Exception  When others then
                         vsalida:='Error al insertar Etiqueta HKTN:  '||sqlerrm;
                    end;
                   
                 
                   
                 
                End if;


        ----dbms_output.put_line('paso etiqueta  f_CURSO_SIU '|| vetiqueta||'-'|| vl_existe  );

     ------ al final se tiene que actualizar el estatus del servicio y el num de transaccion que regresa reza  segun pagado o activo
                  --INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6 )
                -- VALUES('PASO INICIO DE facebook NO4:' ,PPIDM, vetiqueta,pseqno,pCODE, vl_existe);
               --   COMMIT;

       -- -para estas certificaciones no existe codigo padre e hijo entonces se toma directo del accesorio regla de fernando
       --   glovicx 16.080022

            begin
                select  SVRSVAD_ADDL_DATA_CDE code_dtl
                  INTO vcve_dtl_papa
                    from svrsvpr v,SVRSVAD VA
                       where 1=1
                        AND  SVRSVPR_PROTOCOL_SEQ_NO = pseqno
                        AND  SVRSVPR_PIDM   = PPIDM
                        and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                        and va.SVRSVAD_ADDL_DATA_SEQ = '5';

            EXCEPTION WHEN OTHERS THEN
             vcve_dtl_papa := null;
               --dbms_output.put_line('errorn en codigo padre:  '|| sqlerrm  );
             END;
    /*
            begin
                select  SUBSTR(SVRSVAD_ADDL_DATA_CDE,4,2) PROGRAMS
                  INTO VNIVEL
                    from svrsvpr v,SVRSVAD VA
                       where 1=1
                        AND  SVRSVPR_PROTOCOL_SEQ_NO = pseqno
                        AND  SVRSVPR_PIDM   = PPIDM
                        and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                        and va.SVRSVAD_ADDL_DATA_SEQ = '1';

            EXCEPTION WHEN OTHERS THEN
             vcve_dtl_papa := null;
                --dbms_output.put_line('errorn en codigo padre:  '|| sqlerrm  );
             END;





        BEGIN

            select distinct ZSTPARA_PARAM_VALOR
               INTO  VAL_NUM_MES
            from ZSTPARA
            where ZSTPARA_MAPA_ID = 'MESES_GRATIS'
            AND   ZSTPARA_PARAM_ID  =  PCODE
            and   ZSTPARA_PARAM_DESC = VNIVEL;
         EXCEPTION WHEN OTHERS THEN
             VAL_NUM_MES := null;
                --dbms_output.put_line('errorn mrd grstis:  '|| sqlerrm  );
          END ;
        */----------cambuamos la forma de buscar el mes gratis regla fer 27.10.022

           begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  VAL_NUM_MES
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '9'; -- pregunta para el mes gratis
                  exception when others then
                    VAL_NUM_MES  := 0;

                  end;


                    ----------cambuamos la forma de buscar el PROMOCION regla fer 27.10.022
             begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  V_PROMO
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '8'; -- pregunta para la promocion
                  exception when others then
                    V_PROMO  := 0;
                    --dbms_output.put_line('erroR EN MES  grstis:  '|| V_PROMO  );

                  end;

           ----------Buscamos el mail que registro regla fer 08.11.022
             begin
                    select distinct SVRSVAD_ADDL_DATA_DESC
                  INTO  V_mail
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '2'; -- pregunta para el mail de certificaciones
                  exception when others then
                    V_mail  := 'NA';
                     --dbms_output.put_line('erroR EN MES  grstis:  '|| V_mail  );
                  end;

                     ----------Buscamos las nuevas columnas de la pantalla de promociones glovicx 28.07.2023
             begin
                    select distinct SVRSVAD_ADDL_DATA_CDE
                  INTO  V_montodesc
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '20'; -- pregunta para monto descuento
                  exception when others then
                    V_montodesc  := null;
                     --dbms_output.put_line('erroR promociones 20 :  '|| V_mail  );
                  end;
            
             begin
                    select distinct SVRSVAD_ADDL_DATA_CDE
                  INTO  V_numdesc
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '21'; -- pregunta para numero de descuento
                  exception when others then
                    V_numdesc  := null;
                    --dbms_output.put_line('erroR promociones 21 :  '|| V_mail  );

                  end;

               begin   ----- este campo no se envia va nulo
                    select distinct SVRSVAD_ADDL_DATA_CDE
                  INTO  V_cupon
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '22'; -- pregunta para cupon
                  exception when others then
                    V_cupon  := null;
                    --dbms_output.put_line('erroR promociones 22 :  '|| V_cupon  );
                  end;

  ----regla de fernando 11.11.2022 ENVÍO X MAIL  glovicx
  -- valor  "1"  = 0
  -- valor  "1"  = 5
    IF Vsyncro  = 1  THEN
      Vsyncro := 0;
      ELSE
      Vsyncro := 5;
     END IF;






     dbms_output.PUT_LINE('INICIO 5X '|| PPIDM||'-'||VMESES||'-'|| vcve_dtl_papa||','||P_ADID_ID||','|| P_ADID_CODE ||'-'||vsalida);
       IF vsalida = 'EXITO' THEN
             
        
--                    begin  ---- se hace un insert en la bitacora para ver los valores que se insertan de inicio glovicx 10.10.2024
--                         insert into tbitsiu (PIDM,CODIGO,MATRICULA, SEQNO,MONTO,ESTATUS,FECHA_CREA,MATERIA,VALOR16,VALOR17,VALOR18,VALOR19, valor20     )
--                           values (PPIDM, P_ADID_CODE,'TCOTA', pseqno,VDIFERIDO,vcve_dtl_papa, sysdate,vmeses, VAL_NUM_MES,V_FREC_PAGO, V_montodesc,V_numdesc,V_PROMO  );
--                    
--                    
--                     EXCEPTION WHEN OTHERS THEN
--                      NULL;
--                      vsalida := substr(sqlerrm,1,100);
--
--                         -- --dbms_output.put_line('error al insert tztcota  '||vsalida);
--                      END;
--        
        
        
                    BEGIN
                                    --  se le agregan las 3 nuevos parametros pero solo en este codigo las demás llamadas en otros codigos se pueden quedar asi como estan no afectan ptoyecto pantalla de promoiciones glovicx 12-03.2024
                      vsalida :=   BANINST1.PKG_FINANZAS_UTLX.F_INS_CONECTA ( PPIDM, null,  vcampus, vnivel, vprograma, vcve_dtl_papa,pseqno, vmeses, VDIFERIDO, V_PROMO,  trunc(sysdate), trunc(sysdate), P_ADID_CODE, null,VAL_NUM_MES,'A',Vsyncro,V_mail,V_FREC_PAGO,V_montodesc,V_numdesc,null  );

                      EXCEPTION WHEN OTHERS THEN
                      NULL;
                      vsalida := substr(sqlerrm,1,100);

                         -- --dbms_output.put_line('error al insert tztcota  '||vsalida);
                     END;
                      
                       --- si por alguna razon manda error el proceo TCOTA
               IF vsalida  != 'EXITO'  then 
               
--                    begin  ---- se hace un insert en la bitacora para ver los valores que se insertan de inicio glovicx 10.10.2024
--                       insert into tbitsiu (PIDM,CODIGO,SEQNO,MONTO,ESTATUS,FECHA_CREA,MATERIA,VALOR16,VALOR17,VALOR18,VALOR19, valor20     )
--                           values (PPIDM, 'ERROR_NO_inst_COTA',pseqno,VDIFERIDO,vcve_dtl_papa, sysdate,vmeses, VAL_NUM_MES,V_FREC_PAGO, V_montodesc,vsalida,0  );
--                    
--                    
--                    EXCEPTION WHEN OTHERS THEN
--                        NULL;
--                        --vsalida := substr(sqlerrm,1,100);
--
--                         -- --dbms_output.put_line('error al insert tztcota  '||vsalida);
--                    END;
                    null;
              end if;
                
                      
                      
        end if;
            --dbms_output.put_line('paso insert COTA  new certifica '|| vetiqueta||'-'|| vsalida  );


                --INSERT INTO TWPASOW( VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6 )
                -- VALUES('PASO INICIO DE facebook COTA NO5:' ,PPIDM, vcve_dtl_papa,pseqno,pCODE, vsalida);

            IF vsalida = 'EXITO' and PCODE = 'HKTN' and VMESES = '02' THEN-- ajuste htkn glovicx 26.03.25
               vestatus := 'CL';
               else
               vestatus := 'PA';
            end IF;

            IF vsalida = 'EXITO' THEN

                 begin

                        update SVRSVPR  v
                            set SVRSVPR_SRVS_CODE = vestatus,
                              --  V.SVRSVPR_ACCD_TRAN_NUMBER  = vsal_notran,
                                V.SVRSVPR_ACTIVITY_DATE  = SYSDATE
                        WHERE 1=1
                        and   SVRSVPR_PIDM = PPIDM
                        and   V.SVRSVPR_PROTOCOL_SEQ_NO  = pseqno
                        and  SVRSVPR_SRVC_CODE = PCODE ;

                 exception when others then
                  vsalida := substr(sqlerrm,1,99);

                 end;
                ----dbms_output.put_line(' paso 5 face UPDATE SZVPR A CL  '|| vsalida  );


        END IF;


--- VALIDA SI ES plataforma que se envie mail  SIEMPRE SE ENVÍA ESTATUS EN CERO PARA QUE SE INSERTE
     begin
       select DISTINCT 'Y'
            INTO VVALIDA_MAIL
            from ZSTPARA
            where 1=1
            and ZSTPARA_MAPA_ID = 'MAIL_ADDON'
            and ZSTPARA_PARAM_ID = PCODE ;

      exception when others then
       VVALIDA_MAIL := 'N';
       end;



       IF  VVALIDA_MAIL = 'Y' THEN
          vsalida  :=  PKG_SERV_SIU.F_SZTMAIL (PPIDM  , PCODE  , 0 , PSEQNO , NULL  ) ;

        END IF;


     return (vsalida);

EXCEPTION WHEN OTHERS THEN
vsalida := sqlerrm;
--dbms_output.PUT_LINE('SALIDA GRAL F_CURSO_SIU ::: '|| vsalida  );
END F_CURSO_SIU;






FUNCTION F_ONE_FREE ( PPIDM NUMBER, PCODE VARCHAR2 ) RETURN  VARCHAR2 IS
-- Primer funcion para el proeycto de Primer mes GRATIS en la compra de UTELX y CONECTA
-- valida que el estudiante no haya tenido o comprado esta certificación antes
-- regresa un exito o mensaje  glovicx 19.08.022

--segundo paso en la función de f_inserta_servicio se usa esta función para marcar es mes gratis
---  ESDTA FUNCION TAMBIEN SIVE PARA DETECTAR SI SE VA COMPRAR ALGUNA OTRA CERTIFICACIÓN COMO CONECTA, UTELX, O VOXY X EJEMPLO
--  SE DEBE DE VALIDAR QUE NO LA TENGA
-- se grega la validacion para los diplomas QR  glovicx 25.01.2023

vvalida     varchar2(1):= 'N';
vvalida2     varchar2(1):= 'N';
vaccesorio  varchar2(1):= 'N';
P_ADID_CODE varchar2(5):= 'N';
vl_existe   number:=0;
vl_existe2   number:=0;
vtipo_serv   varchar2(20);

BEGIN
   --este filtro solo es ara saber si ya cuenta con alguna certificación
   --  ya que por regls no puede tener mas de una certificación al mismo tiempo glovicx 02.09.022
    --el alumno puede tener una plataforma como utelx o conecta y comprar una certificación

       -------- SE AGREGA NUEVO FLUJO PARA DETENER LAS CERTIFICACIONES Y PLATAFORMAS QUE EL ALUMNO YA COMPRO DESDE SU PKT DE INICIO
      -------  SE RECUPERA LAS ETIQUETAS DE GORADID SI ESTA YA EXISTE ENTONCES QUIERE DECIR QUE LO TIENE EN SU PKT DE VENTAS Y YA NO LO
      ------- LO PUEDE COMPRAR DESDE EL SS1    REGLAS DE VICTOR RMZ  09.09.022
             --VALIDA SI EXISTE LAS ETIQUETAS EN GORADID

      BEGIN
         select distinct g.SZT_TIPO_ALIANZA
           INTO vtipo_serv
        from saturn.SZtGECE g
             where 1=1
              AND G.SZT_CODE_SERV = PCODE;
             --and g.SZT_TIPO_ALIANZA = 'Certificación'
      Exception  When Others then
      P_ADID_CODE := 'N';

     END;

     ----ordenar el IF x tipo, idiomas, certificaciones,plataformas etc.
 IF vtipo_serv = 'Idioma'  then 
   
   vvalida := 'N';   -- esto es x que se pueden comprar diferentes curso o niveles de cada idioma idiomas v2.0 glovicx 22/11/2023

 ELSIF vtipo_serv <> 'Certificación'  THEN  -- AQUIE PLATAFORMA Y EXPERIENCIAS
 
 
      ----- para los idiomas se debera sacar la etiqueta de sazvpr que ahi esta el curso que escogio el alumno}
      ----- por que hay varios niveles o cursos y tienen diferente etiqueta

     -- primero validamos que ese alumno tenga su etiqueta en GORADID-
                 Begin

                    Select count(*)
                     into vl_existe
                    from GENERAL.GORADID
                     Where 1=1
                      AND GORADID_PIDM = ppidm
                      And GORADID_ADID_CODE  IN ( select distinct SZT_ETIQUETA etiqueta
                                                                      from saturn.SZtGECE g
                                                                         where 1=1
                                                                        AND G.SZT_CODE_SERV = PCODE
                                                                        and g.SZT_TIPO_ALIANZA != 'Certificación' 
                                                                        AND  G.SZT_CODE_SERV NOT IN (select ZSTPARA_PARAM_VALOR
                                                                                                        from zstpara
                                                                                                        where 1=1
                                                                                                        and ZSTPARA_MAPA_ID = 'MASCOMP_ETIQUET')
                                                                        );
                    Exception
                    When Others then
                        vl_existe :=0;
                End;



    --CAMINO 1 SOLO VALIDA PLATAFORMAS
      If vl_existe >  0 and  PCODE <> 'HKTN'  then
         --ya existe y no puede comprara otro mas

       ----dbms_output.PUT_LINE('PASO2 DIFERENTE A CERTIFICACIÓN YA TIENE ETIQUETA:. '|| vl_existe||'-'|| vl_existe2 );
       RETURN ('El alumno ya cuenta con el beneficio');
      ELSE
        ----validamos que la certificación exista en PARAMETRIZADOR DE  de 1er MES  GRATIS
       /*   se  quito por instruciones de fernando
        begin

            select distinct 'Y'
              INTO vaccesorio
                from zstpara
                  where 1=1
                    and ZSTPARA_MAPA_ID  = 'MES_GRATIS'
                    and ZSTPARA_PARAM_ID = pcode;


        exception when others then

          vaccesorio  := 'N';
         end;
         */
                --- ahora se usa esta opcion
                begin
                    select distinct 'Y'
                  INTO vaccesorio
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PCODE
                       --   AND  SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '9';
                  exception when others then
                    vaccesorio  := 'N';

                  end;





       ----dbms_output.PUT_LINE('PASO3 MES GRATIS:. '|| vaccesorio );
              IF vaccesorio = 'Y' THEN
                -- validamos la PLATAFORMA  si ya existe una previa no lo deje dejar pasar
                 begin
                      select distinct nvl('Y','N')
                       INTO  vvalida
                        from SVRSVPR  v
                          WHERE 1=1
                            and  v.SVRSVPR_PIDM = PPIDM
                            and  v.SVRSVPR_SRVS_CODE  not in  ('CA','AC')---NOT IN ('AC','PA')
                            ANd    PCODE  NOT IN ( select DISTINCT G.SZT_CODE_SERV
                                                     from sztgece G
                                                        WHERE 1=1
                                                           and g.SZT_TIPO_ALIANZA != 'Certificación' );

                  exception when others then

                  vvalida  := 'N';
                  end;
                ----dbms_output.PUT_LINE('PASO4 MES GRATIS VALIDA:. '|| vvalida );

              END IF;


      END IF;

     -- --dbms_output.PUT_LINE('PASO4XX FINALIZA PLATAFORMAS:. '|| vvalida||'-'||vaccesorio );

 ELSE     ---CERTIFICACIONES

        BEGIN
        Select count(1)
           INTO  vl_existe2
          from GENERAL.GORADID
            Where 1=1
                AND GORADID_PIDM = ppidm
                And GORADID_ADID_CODE  IN ( select distinct SZT_ETIQUETA etiqueta
                                                    from saturn.SZtGECE g
                                                         where 1=1
                                                         and g.SZT_TIPO_ALIANZA = 'Certificación'
                                                          );
      exception when others then
          vl_existe2 := 0;
      end;



          IF vl_existe2 >  0 then
          -- AQUI  ES UNA CERTIFICACIÓN Y SE VALIDA EL NUMERO DE CERTIFICACIONES QUE TIENE
          --ya existe y no puede comprara otro mas
           vvalida := 'Y';
           ----dbms_output.PUT_LINE('PASO2 CERTIFICACIÓN YA TIENE ETIQUETA:. '|| vl_existe||'-'|| vl_existe2 );
            --RETURN ('El alumno ya cuenta con el beneficio');

           ELSE



                   begin
                          select distinct 'Y'
                           INTO  vvalida
                            from SVRSVPR  v
                              WHERE 1=1
                                and  v.SVRSVPR_PIDM = PPIDM
                                and  v.SVRSVPR_SRVS_CODE  not in  ('CA')
                                ANd  V.SVRSVPR_SRVC_CODE  IN ( select DISTINCT G.SZT_CODE_SERV
                                                                from sztgece G
                                                                  WHERE 1=1
                                                                   and g.SZT_TIPO_ALIANZA = 'Certificación' );


                      exception when others then

                      vvalida  := 'N';
                      end;



          END IF;

       ----dbms_output.PUT_LINE('PASO5 YA TIENE UNA CERTIFICACIÓN VALIDA:. '|| vvalida );

  END IF;

  ----dbms_output.PUT_LINE('PASO8 vARIABLES FINALES CERTIFICADO:. '||PCODE||'-'|| vaccesorio ||'-'|| vvalida );


  IF vaccesorio = 'Y' and vvalida = 'Y'  THEN

  ----dbms_output.PUT_LINE('PASO6 NO ES MES GRATIS VALIDA:. '|| vaccesorio ||'-'||vvalida   );

     RETURN ('El alumno ya cuenta con el beneficio');

  ELSIF vaccesorio = 'Y' and vvalida = 'N' THEN -- ESTA ES UNA PLATAFORMA CON MES GRATIS

  ----dbms_output.PUT_LINE('PASO7 este SI ES MES GRATIS VALIDA:. '|| vaccesorio ||'-'||vvalida   );

    RETURN ('EXITO');

  ELSIF vaccesorio = 'N' and vvalida = 'Y' THEN  -- ESTA OPCION ES UNA CERTIFICACIÓN SIN MES GRATIS
   RETURN ('Ya cuenta con una certificación');
     ----dbms_output.PUT_LINE('PASO8 CERTIFICA SIN MES GRATIS:. '|| vaccesorio ||'-'||vvalida   );

  ELSIF vaccesorio = 'N' and vvalida = 'N' THEN  -- ESTA OPCION ES UNA CERTIFICACIÓN NO TIENE NADA
   RETURN ('EXITO');
     ----dbms_output.PUT_LINE('PASO8 CERTIFICA SIN MES GRATIS:. '|| vaccesorio ||'-'||vvalida   );

  ELSE

  ----dbms_output.PUT_LINE('PASO10 NO ES MES GRATIS VALIDA:. '|| vaccesorio ||'-'||vvalida   );
     RETURN ('no cumple');

  END IF;


END F_ONE_FREE;


FUNCTION F_MAIL_SYNCRO (PPIDM NUMBER ) Return VARCHAR2  IS

-- ESTE PROCESO SOLO SE USA PARA ENVIAR EL MAIL A LAS CERTIFICACIONES QUE SE VAN A SINCRONIZAR CON EL AULA
-- GLOVICX 26.10.022


 VEMAIL_ADRRES    varchar2(80);
 VSALIDA    varchar2(300);

-- SE HIZO UN AJUSTE PARA NIVELACIONES  INGLES  glovicx 25/10.022

BEGIN

            SELECT   DISTINCT  GOREMAL_EMAIL_ADDRESS
              INTO VEMAIL_ADRRES
               FROM GOREMAL
                 WHERE     GOREMAL_PIDM = pPidm
                   AND GOREMAL_STATUS_IND  = 'A'
                     AND GOREMAL_EMAL_CODE = 'PRIN';



 RETURN   (VEMAIL_ADRRES);

Exception
            When others  then
       VSALIDA:='Error -- PKG_SERV_SIU.F_MAIL_SYNCRO :'||sqlerrm;

    RETURN (VSALIDA);


END F_MAIL_SYNCRO;



FUNCTION F_CAMBIA_ESTATUS ( PPIDM NUMBER,VCODE VARCHAR2, seqno  number  ) RETURN VARCHAR2  IS

vsalida   VARCHAR2(300):= 'EXITO';
vnumtran   number := 0;
VMONTO    number := 0;


/**
ESTA FUNCIÓN ES EXTERNA Y SE OCUPA DESDE SIU, LA PIDIO FERNANDO, GLOVICX 07/04/2022
Y LA OCUPA PARA LOS ACCESORIOS ABCC.
seguda parte se hace un ajuste para simular la aplicacion de pagos hay accesorios que nacen con costo cero
y tiene que viajar hasta el flujo de COTA pero no se puede hacer aplicación de pagos por que ya esta en cero.
por eso aqui la simulo, glovicx 30.01.2024. para proyecto pantalla de promociones
**/

BEGIN

             begin

                  UPDATE  SVRSVPR  v
                        SET SVRSVPR_SRVS_CODE = 'CL',
                              --  V.SVRSVPR_ACCD_TRAN_NUMBER  = vsal_notran,
                                V.SVRSVPR_ACTIVITY_DATE  = SYSDATE
                        WHERE 1=1
                        and   SVRSVPR_PIDM = PPIDM
                        and   V.SVRSVPR_PROTOCOL_SEQ_NO  = seqno
                        and  SVRSVPR_SRVC_CODE = VCODE ;

             exception when others then
                  vsalida := sqlerrm ; ---substr(sqlerrm,1,99);

             end;

----- buscamos datos para update

      begin
              
        select  distinct V.SVRSVPR_ACCD_TRAN_NUMBER numtran, v.SVRSVPR_PROTOCOL_AMOUNT
          into  vnumtran, VMONTO
          from svrsvpr v,SVRSVAD VA, tbraccd t1
          where 1=1
            and v.SVRSVPR_PIDM = T1.TBRACCD_PIDM
            and V.SVRSVPR_PROTOCOL_SEQ_NO = T1.TBRACCD_CROSSREF_NUMBER
            AND v.SVRSVPR_PROTOCOL_SEQ_NO = seqno
            anD V.SVRSVPR_PIDM     =  ppidm
            and v.SVRSVPR_PROTOCOL_AMOUNT = T1.TBRACCD_BALANCE
            AND v.SVRSVPR_SRVS_CODE != 'CA'
            and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO 
            and V.SVRSVPR_ACCD_TRAN_NUMBER  = T1.TBRACCD_TRAN_NUMBER
            and VA.SVRSVAD_ADDL_DATA_CDE    = T1.TBRACCD_DETAIL_CODE
            and va.SVRSVAD_ADDL_DATA_SEQ = '5'
            AND v.SVRSVPR_PROTOCOL_AMOUNT  = 0   ----SON LOS ACC DE COSTO CERO
            AND v.SVRSVPR_SRVC_CODE IN (select DISTINCT G.SZT_CODE_SERV
                                                from sztgece G
                                                WHERE 1=1
                                                AND G.SZT_CODE_SERV = VCODE)
              order by 1 desc;

      
      
      exception when others then
        vnumtran  := 0;
        vsalida := sqlerrm ; ---substr(sqlerrm,1,99);

      end;
     
   IF VMONTO = 0  THEN  
       --- segunda parte update en ceros. SOLO LOS QUE ASI LO COMPRARON  para proyecto pantalla promociones 
             begin
                            
                  PKG_SERV_SIU.P_CERTIFICA_AUTO (ppidm,seqno, Vcode  );
             
             exception when others then
               vsalida := sqlerrm ; ---substr(sqlerrm,1,99);

             end;
  END IF;
  
  


commit;

RETURN(VSALIDA);

end F_CAMBIA_ESTATUS;

FUNCTION P_CAN_SERV_ESP (PPCODE     VARCHAR2,
                         PPIDM      NUMBER,
                         NO_SERV    NUMBER,
                         PPUSER     VARCHAR2,
                         pcancex     varchar2 DEFAULT NULL)

   RETURN VARCHAR2
IS

/* esta funciones una copia de can_all para cancelar los accesorios, pero desde la nueva pantalla de cancelación especial
lo cual se le quitaron alguna validaciones en la parte de  validar si ya tiene pago o no??
glovicx 03.11.022
SE AGREAGO PARAMETRO Y FUNCIONALIDAD PARA DOBLE PROPOSITO DE LA FUNCIÓN CANCELA ESPECIAL GLOVICX 25.04.2023
LIBERADO new 29.06.2023
*/

   VSALIDA           VARCHAR2 (800) := 'EXITO';
   CONTADOR          NUMBER := 0;
   VDIAS             NUMBER;
   VSERVICIO         VARCHAR2 (4);
   VCODIGO_DTL       VARCHAR2 (6);
   VDESCRP           VARCHAR2 (200);
   LV_TRANS_NUMBER   NUMBER := 0;
   NVAL_CAN          NUMBER := 0;
   VPAGADA           NUMBER := 0;
   VBANDERA          VARCHAR2 (3) := 'NO'; --esta bandera sirve para saber si entra o no en el cursor principal de tbraccd si no entra significa que no hay nada que cancelar
   VMMONTO           NUMBER;
   PCODE_ENV         VARCHAR2 (5);
   PPCODE2           VARCHAR2 (5);
   CUENTA_ENVIO      NUMBER := 0;
   VPAGO_TBRA        NUMBER := 0;
   V_CAMPUS          VARCHAR2 (4);
   VCODE_CURR        VARCHAR2 (8);
   VTRAN_DESC        NUMBER := 0;
   VTRAN_DESC2       NUMBER := 0;
   VPAGO_VALIDA      VARCHAR2 (20);
   VSALDO            NUMBER := 0;
   VPAGADA_V2        NUMBER := 0;
   VTBRAPPL_PAGADA   NUMBER := 0;
   VL_TIPO           VARCHAR2 (2);
   vprograma         VARCHAR2 (20);
   Vcursera          VARCHAR2 (1):= 'N';
   v_code_etiq       varchar2(4):= 'COUR';




/*
PPCODE      VARCHAR2(6):= 'NIVE';
PPIDM       NUMBER   := 280774;
no_serv      number  := 40654;
ppuser      varchar2(20) := 'WWW_USER_CAN';
vmateria    varchar2(14):= 'L2PD101';-----solo para dar de baja la materia de nivelacion
*/
--------esta validacion sirve para ver si ya esta o no cancelado la cartera antes del servicio---
BEGIN
       BEGIN
          SELECT NVL (ROWNUM, 0)
            INTO NVAL_CAN
            FROM TBRACCD TT
           WHERE     TT.TBRACCD_PIDM = PPIDM
                 AND TT.TBRACCD_CROSSREF_NUMBER = NO_SERV
                 AND TT.TBRACCD_DOCUMENT_NUMBER = 'WCANCE'
                 and TBRACCD_CREATE_SOURCE      !=  'ACC_DIFER' ;
       EXCEPTION
          WHEN OTHERS
          THEN
             NVAL_CAN := 0;
       --  INSERT INTO TWPASOW(VALOR1, VALOR2, VALOR3 ) VALUES('P_CAN_SERV_ALL>>1',PPIDM, no_serv   ) ;

       END;

------se agrega esta nueva condición del nuevo parametro si tiene valor entonces solo hace la cancelación caso contrario hace todo normal
--  GLOVICX 25.04.2023
IF pcancex IS NOT NULL THEN
                 BEGIN
                 UPDATE SVRSVPR V
                    SET V.SVRSVPR_SRVS_CODE = 'CA',
                        V.SVRSVPR_USER_ID = PPUSER,                         --'WWW_CAN',
                        V.SVRSVPR_ACTIVITY_DATE = SYSDATE
                  WHERE     1 = 1
                        AND V.SVRSVPR_PIDM = PPIDM
                       -- AND SVRSVPR_SRVS_CODE != 'PA' --CANELA TODO MENOS LO QUE YA ESTE PAGADO
                        AND V.SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV;
              ----dbms_output.PUT_LINE('CANCELACION SOLO DEL SERVICIO:  '||PPIDM ||'-'|| NO_SERV );

              EXCEPTION
                 WHEN OTHERS
                 THEN
                    NULL;
              -- VSALIDA := SQLERRM;
             END;

  VSALIDA := 'EXITO';

ELSE

IF NVAL_CAN > 0    THEN ---si poralguna razon regresa 1 ya existe una cancelacion previa manda exito
      VSALIDA := 'EXITO';

      -- RETURN   VSALIDA;

      -----------------------SI ESTA CANCELADO EN LA CARTERA ES LOGICO QUE CANCELE EL SERVICIO ACTIVO------
      BEGIN
         UPDATE SVRSVPR V
            SET SVRSVPR_SRVS_CODE = 'CA',
                SVRSVPR_USER_ID = PPUSER,                         --'WWW_CAN',
                SVRSVPR_ACTIVITY_DATE = SYSDATE
          WHERE     1 = 1
                AND V.SVRSVPR_PIDM = PPIDM
               -- AND SVRSVPR_SRVS_CODE != 'PA' --CANELA TODO MENOS LO QUE YA ESTE PAGADO
                AND SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV;
      ----dbms_output.PUT_LINE('CANCELACION SOLO DEL SERVICIO:  '||PPIDM ||'-'|| NO_SERV );

      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      -- VSALIDA := SQLERRM;
      END;

      ----dbms_output.PUT_LINE('ya existe una cancelacion previa :: '||'-'||VSALIDA  );
      RETURN VSALIDA;                 ----AQUI REGRESA EXITO YA ESTA CANCELADA
ELSE
      ----dbms_output.PUT_LINE('inicia la cancelacion :: '||'-'||PPCODE ||'-'|| PPIDM ||'-'|| no_serv );
      CUENTA_ENVIO := 0;                                   --vacia la variable



      FOR HI
         IN (  SELECT *
                 FROM TBRACCD TT
                WHERE     TT.TBRACCD_PIDM = PPIDM
                      AND TT.TBRACCD_CROSSREF_NUMBER = NO_SERV
                      AND (   TT.TBRACCD_DOCUMENT_NUMBER != 'WCANCE'
                           OR TT.TBRACCD_DOCUMENT_NUMBER IS NULL)
                      AND TBRACCD_DATA_ORIGIN IN
                             ('WEB-STUOSSR', 'PKG_SWTMDAC', 'Banner', 'ACC_DIFER')
                          ORDER BY 2 DESC)
       LOOP
        ----dbms_output.PUT_LINE('inicia la cancelacion LOOP :: '||'-'||PPCODE ||'-'|| PPIDM ||'-'|| no_serv||'-'||HI.TBRACCD_TRAN_NUMBER );
         VPAGO_VALIDA := '';                             ---INICIA LA VARIABLE
         VSALIDA := 'EXITO';

         --------PRIMERO VALIDAMOS QUE NO ESTE PAGADO POR QUE SE DA EL CASO QUE AUN PAGADO SE PUEDA CANCELAR---GLOVICX 04/08/2019
         --    BEGIN

           VPAGO_TBRA := 0;
            ----dbms_output.PUT_LINE('validacion de NO__PAGO4: '||VPAGO_TBRA||'>>'||  PPIDM|| '-'||  HI.TBRACCD_TRAN_NUMBER||'-'||NO_SERV);

               VPAGADA := 0; --- siempre vale 0


               ----dbms_output.PUT_LINE('ERRORH '||VSALIDA );
               ------------------------calcula el codigo de envio para ver si es internacional------------
               BEGIN
                  SELECT DISTINCT SVRSVPR_WSSO_CODE, SVRSVPR_CAMP_CODE
                    INTO PCODE_ENV, V_CAMPUS
                    FROM SVRSVPR
                   WHERE 1 = 1 AND SVRSVPR_PIDM = PPIDM --AND SVRSVPR_SRVS_CODE = 'AC'
                         AND SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV;

                  CUENTA_ENVIO := CUENTA_ENVIO + 1;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     PCODE_ENV := '';
               END;

               ------------------------------------------------------

            IF    HI.TBRACCD_DATA_ORIGIN = 'PKG_SWTMDAC'
                  OR HI.TBRACCD_CREATE_SOURCE = 'AD'
               THEN
                  ------des -aplica el pago ya que un descuento es como un pago -----

                  PKG_FINANZAS.P_DESAPLICA_PAGOS (PPIDM,HI.TBRACCD_TRAN_NUMBER);

                  /* SE AGREGA VARIABLE PARA IDENTIFICAR TIPO DE MOVIMIENTO  */

                  BEGIN
                     SELECT TBBDETC_DETAIL_CODE CODE_DTL,
                            TBBDETC_DESC DESCP,
                            TBBDETC_TYPE_IND
                       INTO VCODIGO_DTL, VDESCRP, VL_TIPO
                       FROM TBBDETC
                      WHERE     1 = 1
                            AND TBBDETC_TYPE_IND = 'C'
                            AND TBBDETC_DETAIL_CODE IN
                                      SUBSTR (F_GETSPRIDENID (PPIDM), 1, 2)
                                   || 'V2';
                  ---CODIGO DE CANCELACION DE DESCUENTOS ME LO PASO REZA;--nuevo CODIGO LO PASO YAMILET 12/07/022"V2"
                  ----dbms_output.PUT_LINE(' ENTRO A DESAPLICAR EL DESCUENTO(PKG_SWTMDAC) ::'||vcodigo_dtl||'--'|| HI.TBRACCD_TRAN_NUMBER );


                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                  ----dbms_output.PUT_LINE(' error no se encontro code de detalle ::'||CONTADOR );
                  END;

                  VTRAN_DESC := HI.TBRACCD_TRAN_NUMBER; --aqui guarda en la variable en num. de trans del descuento  este se borra
                  VTRAN_DESC2 := HI.TBRACCD_TRAN_NUMBER; --aqui guarda en la variable en num. de trans del descuentoeste se conserva
                  VMMONTO := (HI.TBRACCD_AMOUNT);
               ----dbms_output.PUT_LINE(' SI HAY  code de Descuento ::'||vtran_desc );
               -------aqui hace la validacion de si esta pagada en tbraappl--

               ----dbms_output.put_line('transaccion descuento AD no es pagada ES  DESCUENTO:  '|| VPAGADA  );

            ELSE
               ----dbms_output.put_line('transaccion No hay desc:  '|| VPAGADA  );
                  begin
                    select  SVRSVAD_ADDL_DATA_CDE
                    into vprograma
                        from svrsvpr v,SVRSVAD VA
                         where 1=1
                          and SVRSVPR_SRVC_CODE = PPCODE
                          AND  SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV
                          AND  SVRSVPR_PIDM    = PPIDM
                          and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                          and va.SVRSVAD_ADDL_DATA_SEQ = '1';-- busca el programa


                  exception when others then
                   vprograma := '';

                  end;



                  BEGIN
                     -------------aqui hace la validacion y cambio de codigo de envio internacional----------
                     IF PCODE_ENV = '01UF' AND CUENTA_ENVIO = 1
                     THEN
                        PPCODE2 := PCODE_ENV;
                     ----dbms_output.put_line('entra code envio  inter  '|| PPCODE2 || '-**-'|| cuenta_envio);

                     ELSE
                        NULL;
                        PPCODE2 := PPCODE;
                     ----dbms_output.put_line('NNNOOOO  entra code envio  inter  '|| PPCODE2 || '-**-'|| cuenta_envio );
                     END IF;

                     --------------------------------------------------------

                     /* SE AGREGA VARIABLE PARA IDENTIFICAR TIPO DE MOVIMIENTO  */

                     SELECT DISTINCT
                            TBBDETC_DETAIL_CODE CODE_DTL,
                            TBBDETC_DESC DESCP,
                            TBBDETC_TYPE_IND
                       INTO VCODIGO_DTL, VDESCRP, VL_TIPO
                       FROM TBBDETC T, SZTCCAN ZC
                      WHERE     1 = 1
                            AND TBBDETC_TYPE_IND = 'P'
                            AND TBBDETC_DCAT_CODE IN ('CAN', 'DSC')
                            AND T.TBBDETC_TAXT_CODE  = decode (T.TBBDETC_TAXT_CODE,'GN',T.TBBDETC_TAXT_CODE, substr(vprograma,4,2))
                            AND SUBSTR (T.TBBDETC_DETAIL_CODE, 3, 2) =
                                   SUBSTR (ZC.SZTCCAN_CODE, 3, 2)
                            AND ZC.SZTCCAN_CODE_SERV = PPCODE2
                            AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2) =
                                   SUBSTR (F_GETSPRIDENID (PPIDM), 1, 2);


                     VMMONTO := (HI.TBRACCD_AMOUNT * -1);
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                      --dbms_output.PUT_LINE(' error no se encontro code de detalleXX1  ::'||VMMONTO );
                       begin
                          SELECT DISTINCT
                                TBBDETC_DETAIL_CODE CODE_DTL,
                                TBBDETC_DESC DESCP,
                                TBBDETC_TYPE_IND
                           INTO VCODIGO_DTL, VDESCRP, VL_TIPO
                           FROM TBBDETC T, SZTCCAN ZC
                          WHERE     1 = 1
                                AND TBBDETC_TYPE_IND = 'P'
                            AND TBBDETC_DCAT_CODE IN ('CAN', 'DSC')
                         --   AND T.TBBDETC_TAXT_CODE  = NVL(substr(vprograma,4,2), T.TBBDETC_TAXT_CODE)
                            AND SUBSTR (T.TBBDETC_DETAIL_CODE, 3, 2) =
                                   SUBSTR (ZC.SZTCCAN_CODE, 3, 2)
                            AND ZC.SZTCCAN_CODE_SERV = PPCODE2
                            AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2) =
                                   SUBSTR (F_GETSPRIDENID (PPIDM), 1, 2);
                        exception when others then

                            VCODIGO_DTL := '01B4';
                            VSALIDA := SQLERRM;
                            ----dbms_output.PUT_LINE(' error no se encontro code de detalle2 ::'||VSALIDA );
                        end;

                  END;

                  --AQUI NO ES DESCUENTO Y LIMPIA LA VARIABLE
                  VMMONTO := (HI.TBRACCD_AMOUNT * -1);
                  VTRAN_DESC := 0;
              --  --dbms_output.PUT_LINE(' error no se encontroDESCUENTO  ::'|| vtran_desc || '---'|| hi.TBRACCD_TRAN_NUMBER  );
            END IF;

               --------valida tbrappl  PARA VER SI YA ESTA PAGADO O NO EL SERVICIO
               -- --dbms_output.PUT_LINE('REGS--en VALIDA SI EXITE UN PAGOOOXX2 -'||'-'||Jump.pidm||'-'||Jump.seq_no||'-'|| jump.code||'-'||VPAGO_TBRA||'-'||HI.TBRACCD_TRAN_NUMBER ||'-'|| VPAGADA ||'--'||vtran_desc );

               BEGIN
                  SELECT ZSTPARA_PARAM_VALOR
                    INTO VCODE_CURR
                    FROM ZSTPARA
                   WHERE     ZSTPARA_MAPA_ID = 'CAMPUS_AUTOSERV'
                         AND ZSTPARA_PARAM_ID = V_CAMPUS; ---ESTE ES EL CAMPUS
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VCODE_CURR := 'Error :' || SQLERRM;
                     -- vigencia := 0;
                     VSALIDA := 'Error en codigo de moneda :' || SQLERRM;
               END;

               ----dbms_output.PUT_LINE('ERRORC '||VPAGADA|| '-'||VMMONTO  );
                --valida si es cursera coursera glovicx 04/10/2021
                 begin
                    select 'Y'
                       INTO  Vcursera
                     From ZSTPARA
                       where 1=1
                        AND ZSTPARA_MAPA_ID = 'CODI_NIVE_UNICA'
                        and ZSTPARA_PARAM_DESC like('COURSERA%')
                        and ZSTPARA_PARAM_ID = PPCODE;


                 exception when others then
                 Vcursera := 'N';
                 end;




                IF  Vcursera = 'Y'    THEN
                        --ejecuta la funcion de CHUY para cancelar coursera glovicx 04/10/2021
                   VSALIDA := BANINST1.PKG_SENIOR.F_CANCELA_COUR ( PPIDM );
                   ----dbms_output.put_line(' cancela la F_CHUY  '|| VSALIDA );
                   ----tambien tiene que cancelar o quitar la etiqueta de goradid
                    PKG_FREEMIUM.quita_etiqueta(ppidm, v_code_etiq);
                   ----dbms_output.put_line(' cancela la ETIQUETA  '|| VSALIDA );
                end if;

             --------
               BEGIN
                  SELECT NVL (MAX (TBRACCD_TRAN_NUMBER), 0) + 1
                    INTO LV_TRANS_NUMBER
                    FROM TBRACCD
                   WHERE TBRACCD_PIDM = PPIDM;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     VSALIDA := 'Error :' || SQLERRM;
                     LV_TRANS_NUMBER := 0;
               END;

               ---------------------------------------
             IF VPAGADA = 0
               THEN
                  --------------------------------------------inserta la cancelacion de  tbraccd---
                  BEGIN
                     INSERT INTO TBRACCD (TBRACCD_PIDM,
                                          TBRACCD_TERM_CODE,
                                          TBRACCD_DETAIL_CODE,
                                          TBRACCD_USER,
                                          TBRACCD_ENTRY_DATE,
                                          TBRACCD_AMOUNT,
                                          TBRACCD_BALANCE,
                                          TBRACCD_EFFECTIVE_DATE,
                                          TBRACCD_DESC,
                                          TBRACCD_CROSSREF_NUMBER,
                                          TBRACCD_SRCE_CODE,
                                          TBRACCD_ACCT_FEED_IND,
                                          TBRACCD_SESSION_NUMBER,
                                          TBRACCD_DATA_ORIGIN,
                                          TBRACCD_TRAN_NUMBER,
                                          TBRACCD_ACTIVITY_DATE,
                                          TBRACCD_MERCHANT_ID,
                                          TBRACCD_TRANS_DATE,
                                          TBRACCD_DOCUMENT_NUMBER,
                                          TBRACCD_FEED_DATE,
                                          TBRACCD_STSP_KEY_SEQUENCE,
                                          TBRACCD_PERIOD,
                                          TBRACCD_CURR_CODE,
                                          TBRACCD_TRAN_NUMBER_PAID,
                                          TBRACCD_RECEIPT_NUMBER)
                          VALUES (PPIDM,
                                  HI.TBRACCD_TERM_CODE,
                                  VCODIGO_DTL,                    --VCODE_DTL,
                                  PPUSER,                        -- 'WWW_CAN',
                                  SYSDATE,
                                  HI.TBRACCD_AMOUNT,
                                  VMMONTO,          ---(HI.TBRACCD_AMOUNT*-1),
                                  (SYSDATE),
                                  VDESCRP,
                                  NO_SERV,
                                  'T',
                                  'Y',
                                  0,
                                  'WEB-BAJA_JOB',
                                  LV_TRANS_NUMBER,
                                  SYSDATE,
                                  NULL,
                                  SYSDATE,
                                  LV_TRANS_NUMBER,
                                  HI.TBRACCD_FEED_DATE,
                                  HI.TBRACCD_STSP_KEY_SEQUENCE,
                                  HI.TBRACCD_PERIOD,
                                  VCODE_CURR                           --'MXN'
                                            ,
                                  HI.TBRACCD_TRAN_NUMBER,
                                  HI.TBRACCD_RECEIPT_NUMBER);


                     CONTADOR := CONTADOR + SQL%ROWCOUNT;
                  EXCEPTION
                     WHEN OTHERS
                     THEN
                        NULL;
                        VSALIDA := SQLERRM;
                  ----dbms_output.PUT_LINE('error al insertar tbraccd code cancelacion::'||VSALIDA );
                  END;
                   -- --dbms_output.PUT_LINE('inserta en tbraccd ::'||VSALIDA );

                  /* SE AGREGA UPDATE PARA EL DESCUENTO ASOCIADO AL ACCESORIO Y LIBERAR   ESTO LO LIBERO  REZA*/

                  IF VL_TIPO = 'P'  THEN
                     UPDATE TBRACCD
                        SET TBRACCD_TRAN_NUMBER_PAID = NULL
                      WHERE     TBRACCD_PIDM = PPIDM
                            AND TBRACCD_TRAN_NUMBER_PAID =
                                   HI.TBRACCD_TRAN_NUMBER
                            AND TBRACCD_TRAN_NUMBER != LV_TRANS_NUMBER;
                  END IF;

                  IF VPAGADA = 0 AND VL_TIPO = 'P'  THEN
                     BEGIN
                        UPDATE TBRACCD
                           SET TBRACCD_DOCUMENT_NUMBER = 'WCANCE',
                               TBRACCD_TRAN_NUMBER_PAID = NULL
                         WHERE     TBRACCD_PIDM = PPIDM
                               AND TBRACCD_TRAN_NUMBER =
                                      HI.TBRACCD_TRAN_NUMBER
                               AND TBRACCD_CROSSREF_NUMBER = NO_SERV;

                        CONTADOR := CONTADOR + SQL%ROWCOUNT;
                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           VSALIDA := SQLERRM;
                     END;

                     BEGIN
                        UPDATE SVRSVPR V
                           SET SVRSVPR_SRVS_CODE = 'CA',
                               SVRSVPR_USER_ID = PPUSER,          --'WWW_CAN',
                               SVRSVPR_ACTIVITY_DATE = SYSDATE
                         WHERE     1 = 1
                               AND V.SVRSVPR_PIDM = PPIDM
                              -- AND SVRSVPR_SRVS_CODE != 'PA' --CANELA TODO MENOS LO QUE YA ESTE PAGADO
                               AND SVRSVPR_PROTOCOL_SEQ_NO = NO_SERV;


                     EXCEPTION
                        WHEN OTHERS
                        THEN
                           NULL;
                           VSALIDA := SQLERRM;
                     END;
                    END IF;
               END IF; --PAGADA

               VBANDERA := 'YES';
           -- --dbms_output.PUT_LINE('CACELACION FINAL DEL SERVICIO Y CARTERA'||PPIDM ||'-'|| NO_SERV );
            ---   COMMIT;


     END LOOP;                                          --END LOOP DE TBRACCD

     --dbms_output.PUT_LINE('salidax '||VSALIDA );
END IF; -- IF GRAL  INICIAL
END IF;  -- IF NUEVO PARAMETRO PCANCEX
      --
      IF VSALIDA = 'EXITO' AND VPAGADA = 0
      THEN
         RETURN (VSALIDA);

         ----dbms_output.PUT_LINE('salida_DE REGS Con exito:  '||VSALIDA );
         COMMIT;
      ELSE
         ROLLBACK;

         --  INSERt INTO TWPASOW(VALOR1, VALOR2, VALOR3,VALOR4, valor5)
         --        VALUES('ESTOY EN TRABCCD vsalida FRACSO2 tbra ', VSALIDA, PPIDM, PPcode,lv_trans_number  );
         --     ------como es muy problabe que ya haya insertado el descuento en la pasada anterior hay que borrar el desc.
         --PPCODE VARCHAR2, PPIDM NUMBER , no_serv number,
         DELETE TBRACCD
          WHERE     TBRACCD_PIDM = PPIDM
                AND TBRACCD_TRAN_NUMBER = LV_TRANS_NUMBER ---ESTE ES EL ÚLTIMO REGS QUE GUARDO
                AND TBRACCD_CROSSREF_NUMBER = NO_SERV;

         COMMIT;

         -----------------------------
         VSALIDA := 'ERROR'||SQLERRM;

         RETURN (VSALIDA);
          --dbms_output.PUT_LINE('ERRORww  ROOLBACK '||VSALIDA );


        END IF;




EXCEPTION    WHEN OTHERS    THEN
      VSALIDA := 'Error :' || SQLERRM;
    --  ROLLBACK;
      RETURN VSALIDA;
--  --dbms_output.PUT_LINE('Error general--  '|| VSALIDA);

END P_CAN_SERV_ESP;


FUNCTION F_CANCE_CUR_SIU ( pmatricula in varchar2 ) RETURN PKG_SERV_SIU.cancela_siu_type
IS
cur_ACCESORIOS  SYS_REFCURSOR;

vsalida     varchar2(200):= 'EXITO';
vcrn        varchar2(6);
VEST_MATE   VARCHAR2(4);
VCVE_MATE   VARCHAR2(14);
vtran_desc  NUMBER:= 0;
vmonto_desc NUMBER:= 0;
VTIPOG      VARCHAR2(8):= 'ACCE';
VETIQUETA   VARCHAR2(8);
VDIAS       NUMBER:= 0;
Vcota_estatus VARCHAR2(8);
vestatusG     VARCHAR2(30);
vcota_code    VARCHAR2(10);
V_GORADID     VARCHAR2(6):='N';

/*
ESTA FUNCIÓN SE HACE PARA EL PROYECTO DE CANCELACIONES INTERNAS DE SERVICIOS ESCOLARES A LOS ACCESORIOS QUE SE COMPARARON
DESDE SIU Y YA NO SE QUIEREN O SE APLICARON MAL, Y SE TIENE QUE HACER EL AJUSTE.
ESTA ES LA PRIMER PARTE EL CURSO DE LOS ACCESORIOS QUE ESTAN DISPONIBLES PARA LA CANCELACION
GLOVICX 20/05/022
*/

BEGIN

NULL;

        begin

        delete
        from  saturn.STCANCE_ACCE tz
        where 1=1
        and TZ.TCANCE_PIDM = fget_pidm(pmatricula);

        exception when others then
        null;
        end;

        BEGIN
           select DISTINCT ZSTPARA_PARAM_VALOR
             INTO VDIAS
            from zstpara
            where 1=1
            and ZSTPARA_MAPA_ID = 'CANCEL_AUTOSERV';


        EXCEPTION WHEN OTHERS THEN
        VDIAS  := 0;
        END;


--- CURSO RINCUPAL PARA SACAR AL MASIVO DE DATOS
FOR JUMP IN (select DISTINCT SVRSVPR_PIDM PIDM,  SVRSVPR_SRVC_CODE CODE, SVRSVPR_PROTOCOL_SEQ_NO SEQNO, SVRSVPR_ACCD_TRAN_NUMBER TRANUM,
                    SVRSVPR_PROTOCOL_AMOUNT MONTO,SVVSRVC_DESC NOMBRE, SVVSRVS_DESC ESTATUS
                from svrsvpr v,SVRSVAD VA,SVVSRVC VC, SVVSRVS RS
                    where 1=1
                        AND V.SVRSVPR_SRVC_CODE  = VC.SVVSRVC_CODE
                        AND V.SVRSVPR_SRVS_CODE  = RS.SVVSRVS_CODE
                        AND v.SVRSVPR_PIDM  = FGET_PIDM(pmatricula)
                        and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                        AND SVRSVPR_SRVS_CODE NOT IN ('CA')
                        and va.SVRSVAD_ADDL_DATA_SEQ = '1'
                        and V.SVRSVPR_PROTOCOL_SEQ_NO  not in (select distinct  f.SFRSTCR_STRD_SEQNO --aqui excluye las materias que y tiene calificación no se puden cancelar
                                                                from sfrstcr f
                                                                where 1=1
                                                                and v.SVRSVPR_PIDM = f.SFRSTCR_PIDM
                                                                and  V.SVRSVPR_PROTOCOL_SEQ_NO = f.SFRSTCR_STRD_SEQNO
                                                                and F.SFRSTCR_RSTS_CODE  = 'RE'
                                                                and F.SFRSTCR_GRDE_CODE  IS not NULL
                                                                and substr(F.SFRSTCR_TERM_CODE,5,1)  = '8'
                                                                )
                         and V.SVRSVPR_PROTOCOL_SEQ_NO  not in  (select distinct SZT_SEQNO_SIU -- en esta parte excluye los QR que ya fueron entregados esos no se pueden cancelar
                                                from SZTQRDG q
                                                where 1=1
                                                and v.SVRSVPR_PIDM = q.SZT_PIDM
                                                and V.SVRSVPR_PROTOCOL_SEQ_NO = q.SZT_SEQNO_SIU
                                                and q.SZT_ENVIO_ALUMNO = 1
                                                and q.SZT_FECHA_ENVIO  is not null)
                         AND TRUNC(V.SVRSVPR_RECEPTION_DATE)  >= TRUNC(SYSDATE) - VDIAS
                         order by 2 desc  ) LOOP

--setemos las variables
vcrn   := NULL;
VEST_MATE := NULL;
VCVE_MATE := NULL;
vtran_desc  := 0;
vmonto_desc := 0;
VETIQUETA  := null;
VTIPOG     := NULL;
vestatusG  := null;
Vcota_estatus := null;


         BEGIN


            SELECT 'ACCE'
              INTO VTIPOG
            FROM  zstpara
            WHERE 1=1
            AND zstpara_mapa_id ='AUTOSERVICIOSIU'
            AND ZSTPARA_PARAM_ID = JUMP.CODE;


         EXCEPTION WHEN OTHERS THEN
         VTIPOG := 'NADA';

         END;


  ----dbms_output.put_line('saliendo ACCE:  '||JUMP.CODE ||'-'|| VTIPOG  );

-- SI ES NIVE SACAMOS DATOS EXTRAS

IF JUMP.CODE = 'NIVE'  THEN
--VOY A BUSCAR EL CRN, ESTATUS DE L AMATERIA,
   BEGIN
        select SFRSTCR_CRN CRN, SFRSTCR_RSTS_CODE EST_MATE, SFRSTCR_RESERVED_KEY CVE_MATE
           INTO vcrn, VEST_MATE, VCVE_MATE
            from sfrstcr f
                where 1=1
                    and SFRSTCR_PIDM = JUMP.PIDM
                    --and F.SFRSTCR_RSTS_CODE  = 'RE'
                    and F.SFRSTCR_GRDE_CODE  IS NULL
                    and substr(F.SFRSTCR_TERM_CODE,5,1)  = '8'
                    and SFRSTCR_STRD_SEQNO = JUMP.SEQNO;

   EXCEPTION WHEN OTHERS  THEN
   vcrn   := NULL;
   VEST_MATE := NULL;
   VCVE_MATE := NULL;
   --dbms_output.put_line('error en NIVE: '|| JUMP.PIDM ||'-'|| JUMP.SEQNO );



   END;


END IF;





--BUSCO LA INFORMACIÓN DEL DESCUENTO SI ES QUE TIENE--

    BEGIN

        select TBRACCD_TRAN_NUMBER tran_desc,tBRACCD_AMOUNT monto_desc
            into vtran_desc, vmonto_desc
            from tbraccd t
                where 1=1
                    and tbraccd_pidm = JUMP.PIDM
                    AND T.TBRACCD_CREATE_SOURCE = 'AD'
                    AND TBRACCD_CROSSREF_NUMBER = JUMP.SEQNO ;

    EXCEPTION WHEN OTHERS THEN
      vtran_desc  := 0;
      vmonto_desc := 0;
      --dbms_output.put_line('error en descuento: '|| JUMP.PIDM ||'-'|| JUMP.SEQNO );
    END;



-----BUSCA SI EL ACCESORIO ES CERTIFICADO Y SACA LA ETIQUETA DE COTA

     BEGIN
            SELECT DISTINCT TZTCOTA_ORIGEN, 'CERT', TZTCOTA_STATUS, TZTCOTA_CODIGO
              INTO   VETIQUETA, VTIPOG,  Vcota_estatus , vcota_code
            FROM TZTCOTA T2
            WHERE 1=1
            AND t2.TZTCOTA_PIDM = jump.pidm
            AND t2.TZTCOTA_SERVICIO  = jump.seqno
            AND T2.TZTCOTA_SEQNO  = (select  max (t3.TZTCOTA_SEQNO)  from TZTCOTA T3
                                                where 1=1
                                                AND t2.TZTCOTA_PIDM = t3.TZTCOTA_PIDM
                                                AND t2.TZTCOTA_SERVICIO  = t3.TZTCOTA_SERVICIO );

     EXCEPTION WHEN  NO_DATA_FOUND  THEN
     NULL;
      ----dbms_output.put_line('error no datos en COTA: '|| JUMP.PIDM ||'-'|| JUMP.SEQNO );
       VETIQUETA  := '';
       --VTIPOG    := '';
     WHEN OTHERS THEN
       VETIQUETA  := '';
      -- VTIPOG     := '';
      ----dbms_output.put_line('error no others  en COTA: '|| JUMP.PIDM ||'-'|| JUMP.SEQNO );
     END;

    -- --dbms_output.put_line('salir de COTA: '|| JUMP.PIDM ||'-'|| JUMP.CODE ||'-'||VTIPOG );

    IF VTIPOG = 'CERT' then

      vestatusG :=  Vcota_estatus;
      ----dbms_output.put_line('el tipo en ACCE IF : '|| vestatusG ||'-'|| JUMP.CODE ||'-'||VTIPOG );

     ELSE
     vestatusG  := jump.estatus;
     vcota_code := NULL;
     ----dbms_output.put_line('el tipo en ACCE ELSE : '|| vestatusG ||'-'|| JUMP.CODE ||'-'||VTIPOG );
     END IF;

     --------BUSCA SI ESTA ACTIVA O NO LA ETIQUETA EN GORADID.
     BEGIN
        SELECT 'Y' existe
           INTO V_GORADID
            FROM GORADID G
              WHERE 1=1
                AND G.GORADID_PIDM = JUMP.PIDM
                AND G.GORADID_ADID_CODE = VETIQUETA;

     EXCEPTION WHEN OTHERS THEN
       V_GORADID  := 'N';
     ----dbms_output.put_line('Error no existe etiqueta GORADID : '|| vestatusG ||'-'|| JUMP.CODE ||'-'||VTIPOG );
     END;





  ---IF VTIPOG <> 'NADA' THEN   se le quito esta opcion para que deje pasar las certificaciones que no tengan etiqueta o cota
  --   nueva regla Betzy 18.11.2022
    BEGIN
    insert into saturn.STCANCE_ACCE (  TCANCE_PIDM,TCANCE_CODE,TCANCE_SEQNO,TCANCE_CRN,TCANCE_CVEMATE,TCANCE_ESTMATE,TCANCE_TRANUM,TCANCE_TRANNUM_DESC,TCANCE_NOMBRE,TCANCE_MONTO,
                               TCANCE_MONTO_DESC,TCANCE_ESTATUS,TCANCE_ETIQUETA, TCANCE_TIPO,TCANCE_DTLLE_CODE,TCANCE_CDE_GORADID)
    VALUES( jump.pidm,jump.code,jump.seqno,vcrn,VCVE_MATE,VEST_MATE,jump.tranum,vtran_desc,jump.nombre,jump.monto,vmonto_desc, vestatusG ,VETIQUETA, VTIPOG,vcota_code,V_GORADID );

    EXCEPTION WHEN OTHERS THEN

    VSALIDA := SQLERRM;
    ----dbms_output.put_line('error en INSERT final: '|| JUMP.PIDM ||'-'|| JUMP.SEQNO||'-'|| jump.code||'-'||VSALIDA );
    END;

       -- --dbms_output.put_line('salida INSERT: '|| jump.pidm||'-'|| jump.code||'-'|| jump.seqno||'-'|| vcrn||'-'|| VCVE_MATE||'-'||VEST_MATE||'-'|| jump.tranum||'-'||vtran_desc||'-'||
        --              jump.nombre||'-'|| jump.monto||'-'||vmonto_desc ||'-'|| jump.estatus ||'-'||VTIPOG   );
 --END IF;


commit;


END LOOP;


----dbms_output.put_line('salidaXXX TIPO: '|| VTIPOG ||'-'|| VDIAS);


open cur_ACCESORIOS  for
                             select TCANCE_CODE,
                                TCANCE_SEQNO,
                                TCANCE_CRN,
                                TCANCE_CVEMATE,
                                TCANCE_ESTMATE,
                                TCANCE_TRANUM,
                                TCANCE_TRANNUM_DESC,
                                TCANCE_NOMBRE,
                                TCANCE_MONTO,
                                TCANCE_MONTO_DESC,
                                TCANCE_ESTATUS,
                                TCANCE_ETIQUETA,
                                TCANCE_TIPO,
                                TCANCE_DTLLE_CODE,
                                TCANCE_CDE_GORADID
                           from STCANCE_ACCE
                           where 1=1
                             and TCANCE_PIDM = fget_pidm(pmatricula)
                             order by TCANCE_SEQNO desc
                             ;

RETURN cur_ACCESORIOS;

EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;
--RETURN vsalida;
----dbms_output.put_line('error gral de la funcion cance_cur_siu '|| vsalida  );

END  F_CANCE_CUR_SIU;


FUNCTION F_CANCE_ID_SIU  (PPIDM IN NUMBER, PCODE IN VARCHAR2, PSEQNO IN NUMBER  ) RETURN VARCHAR2
IS
/*
SEGUNDA PARTE DEL PROYECTO DE CANCELACIÓN DE ACCESORIOS SIU, AUI YA SE HACE EL CAMBIO DE ESTATUS A "CA" Y SE DA DE BAJA LA MATERIA "DD"
--GLOVICX 23/05/022
*/

vsalida   VARCHAR2(300):= 'EXITO';
vtume_materia   VARCHAR2(30);
vtume_id         VARCHAR2(30);
vtume_stardate    VARCHAR2(30);
vtume_period       VARCHAR2(30);
VSALIDA_stume  VARCHAR2(300):= 'EXITO';

BEGIN

-- DIVIDIMOS EL ESCENARIO EN 2;  NIVELACIONES Y LOS DEMAS

IF PCODE = 'NIVE' then
     ---actualiza el estatus de la materia la da de baja "DD"
    begin

      Update  SFRSTCR r
         SET r.SFRSTCR_RSTS_CODE = 'DD',
             R.SFRSTCR_USER_ID  = 'WWW_CAN_SIU',
             R.SFRSTCR_ACTIVITY_DATE  = sysdate
        where 1=1
           and r.SFRSTCR_PIDM = ppidm
            and r.SFRSTCR_GRDE_CODE  is null
            and substr(r.SFRSTCR_TERM_CODE,5,1)  = '8'
            and r.SFRSTCR_STRD_SEQNO = pseqno;

    exception when others then

    vsalida := sqlerrm;

    ----dbms_output.put_line('error en la cancelacion de la materia  '|| vsalida  );
    end;

     ---se manda la cancelación de la sincronización--
     ---primero validamos si existe y extraemos los datos--para la cancelación
     BEGIN
        SELECT DISTINCT zu.SZSTUME_TERM_NRC, zu.SZSTUME_ID, zu.SZSTUME_START_DATE, gp.SZTGPME_TERM_NRC_COMP
            INTO vtume_materia, vtume_id, vtume_stardate, vtume_period
             FROM SZSTUME zu, SZTGPME gp
              WHERE 1=1
                AND zu.SZSTUME_NO_REGLA = 99
                AND zu.SZSTUME_PIDM  = PPIDM --364008
                AND zu.SZSTUME_POBI_SEQ_NO = pseqno --95236
                and zu.SZSTUME_TERM_NRC = GP.SZTGPME_TERM_NRC
                and gp.SZTGPME_NO_REGLA = 99
                and gp.SZTGPME_START_DATE = (select max (GP2.SZTGPME_START_DATE) from SZTGPME gp2
                                                where 1=1
                                                 and GP2.SZTGPME_NO_REGLA = 99
                                                 and zu.SZSTUME_TERM_NRC = gp2.SZTGPME_TERM_NRC);
     EXCEPTION WHEN OTHERS THEN
     vsalida := sqlerrm;

       -- --dbms_output.put_line('error en extrae datos de SZTUME  '|| vsalida  );
     END;

     IF vsalida = 'EXITO' AND vtume_materia IS NOT NULL  THEN   ----- AQUI SE MANDA LA CANCELACIÓN DE LAS TABLAS DE SINCRONIZACIÓN
          VSALIDA_stume := PKG_NIVE_AULA.F_inst_SZSTUME (vtume_materia, Ppidm, vtume_id, vtume_stardate, vtume_period, pseqno,'DD'  ) ;
     END IF;

END IF;

----dbms_output.put_line('AL TERMINAR EL UPDATE A LA MATERIA   '|| vsalida  );

--- primero va lanzar la funcion de Gibran para cancelar el estado de cuenta -- si regresa EXITO entonces ya mando
--la cancelación del accesorio.

begin
--- se quito esta funcion por regla de fernando 27.10.022
 --vsalida := PKG_FINANZAS_UTLX.CANCE_PACCESORIOS ( PPIDM, pseqno );
  -- vsalida := PKG_FINANZAS.F_CANC_SERV ( PPIDM, pseqno );
null;

exception when others then

vsalida := 'Fallo la cancelación de la cartera:' || sqlerrm;
----dbms_output.put_line('error en funcion de gibtran   '|| vsalida  );
end;

----dbms_output.put_line('despues de la funcion de gibtran   '|| vsalida  );


IF vsalida = 'EXITO'  then

---aqui cancela el accesorio general--

   begin

        UPDATE  SVRSVPR  v
           SET   SVRSVPR_SRVS_CODE  = 'CA',
                 SVRSVPR_ACTIVITY_DATE  = sysdate,
                 SVRSVPR_USER_ID  = 'WWW_CAN_SIU'
            WHERE 1=1
               and   SVRSVPR_PIDM = ppidm
               and  V.SVRSVPR_PROTOCOL_SEQ_NO  = pseqno
               and  SVRSVPR_SRVS_CODE  not in  ('CA')---NOT IN ('AC','PA')
               and  V.SVRSVPR_SRVC_CODE = pcode;


   exception when others then

    vsalida := sqlerrm;

    --dbms_output.put_line('error en la cancelacion de la materia  '|| vsalida  );

   end;

----dbms_output.put_line('AL TERMINAR EL UPDATE AL ACCESORIO GRAL   '|| vsalida  );
-- SE METIO LA CANCELACION ESPECIAL DE LA CARTERA EN ESTE FLUJO X SUGERENCIA DE BETZY PARA SEGUIR FLUJO NORMAL DE AUTO SERV
--  GLOVICX 16.11.2022
      begin
 VSALIDA := BANINST1.PKG_SERV_SIU.P_CAN_SERV_ESP (PCODE , PPIDM , pseqno , 'WWW_CAN_ESP' );
     exception when others then
     vsalida := sqlerrm;

     dbms_output.put_line('error en la funcion de cancelacion especial  '|| vsalida  );
     end;
 
COMMIT;

ELSE
VSALIDA := 'Fallo la cancelación de la cartera:';

END IF;



RETURN VSALIDA;



exception when others then

vsalida := sqlerrm;

    ----dbms_output.put_line('error gral de f_cance_id_siu  '|| vsalida  );


END F_CANCE_ID_SIU;


FUNCTION F_VALIDA_COSTO_CERO ( PCODE VARCHAR2)  RETURN VARCHAR2 IS
--ESTA FUNCION SE EJECUTA DESDE F_INSRT_SERV Y LO QUE HACE ES VALIDAR EL ACCESORIO QUE SE ESTA COMPRANDO SI ESE ACCESORIO ESTA
--  EN EL PARAMETRIZADOR REGRESA UN EXITO, SIGNIFICA QUE ES UN ACCESORIO CON COSTO CERO Y LO DEBE DEJAR PASAR LA VALIDACION DE
-- al parecer ya no se usa al que revisar bien 01.12.2022 glovicx
--Agrupador:
--PROCESO_AUTOSER
VVALIDA NUMBER:=0;
VSALIDA   VARCHAR2(100);

BEGIN


select COUNT(1)
INTO VVALIDA
from ZSTPARA
where 1=1
and ZSTPARA_MAPA_ID ='PROCESO_AUTOSER'
AND  ZSTPARA_PARAM_ID  = PCODE ;



IF VVALIDA >= 0 THEN
RETURN 'EXITO'; --QUIERE DECIR QUE SI TIENE VALOR CERO
ELSE
RETURN 'ERROR';-- ESTE ACCESORIO SI TIENE VALOR

END IF;



EXCEPTION WHEN OTHERS THEN

VSALIDA  := SQLERRM;
RETURN VSALIDA;


END F_VALIDA_COSTO_CERO;


FUNCTION F_UCAMP_CURSOS  RETURN PKG_SERV_SIU.cur_ucamp_type
IS

VSALIDA  VARCHAR2(300);
cur_ucamp  SYS_REFCURSOR;

BEGIN
-- este curso regresa todos los cursos que existen en UCAMP y lo seleccionen en las preguntas del SS1
-- este se ocupa para los combos de cursos en siu.glovicx 13.09.022

open cur_ucamp  for
                        --select DISTINCT ZSTPARA_PARAM_ID||'|'||ZSTPARA_PARAM_VALOR oculto
                           select DISTINCT  ZSTPARA_PARAM_VALOR oculto
                            , ZSTPARA_PARAM_DESC mostrar
                           from ZSTPARA
                            where ZSTPARA_MAPA_ID = 'UCAM_CUR' ;


RETURN cur_ucamp;

EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;


END F_UCAMP_CURSOS;


FUNCTION F_SZTMAIL (PPIDM  NUMBER, PADDON  VARCHAR2, PESTATUS  NUMBER DEFAULT 0, PSEQNO NUMBER, POBSERVA VARCHAR )  RETURN VARCHAR2
IS
--funcion que se utiliza para insertar en la tabla intemedia para UCAMP pueda tomar los regs y enviar el mail
--- tambien la utiliza PYTHON para actualizar los registros segun si eststus glovicx 21.09.022

VSERV   VARCHAR2(30);
VNIVEL  VARCHAR2(2);
VSALIDA VARCHAR2(250):= 'EXITO';
VCAMPUS VARCHAR2(4);


BEGIN
NULL;

IF  PESTATUS = 0 THEN


 ------insertamos segun estsus = 0
     begin

        select  SVRSVPR_SRVC_CODE, SUBSTR(SVRSVAD_ADDL_DATA_CDE,4,2),SVRSVPR_CAMP_CODE
                INTO VSERV, VNIVEL, VCAMPUS
          from svrsvpr v,SVRSVAD VA
            where 1=1
              AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
              anD  SVRSVPR_PIDM    = PPIDM
              and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
              and va.SVRSVAD_ADDL_DATA_SEQ = '1';


     EXCEPTION when others then
     VSERV  := NULL;
     VNIVEL := NULL;
     VCAMPUS  := NULL;

     end;

     ---INSERTA NUEVO
     BEGIN

       INSERT INTO SZTMAIL     (PIDM,
                                ADDON,
                                CAMPUS,
                                NIVEL,
                                STAT_IND,
                                OBSERVACIONES,
                                PSEQNO,
                                FECHA_ACTIVIDAD,
                                USUARIO )
          VALUES( PPIDM,VSERV,VCAMPUS,VNIVEL,PESTATUS, POBSERVA,PSEQNO,SYSDATE, USER );


     EXCEPTION when others then

     VSALIDA  := SQLERRM;
     end;


ELSE
  --- HACE EL UPDATE QUE VIENE DESDE PYTHON DIRECTO
    BEGIN

        UPDATE SZTMAIL
           SET STAT_IND     = PESTATUS,
               OBSERVACIONES = POBSERVA
        WHERE 1=1
           AND PIDM = PPIDM
           AND ADDON = PADDON;

     EXCEPTION when others then
     VSALIDA  := SQLERRM;

     end;




END IF;


RETURN (VSALIDA);



END F_SZTMAIL;

FUNCTION F_MATERIA_NIVE_INGLES (PPIDM NUMBER, pprogram varchar2 ) Return VARCHAR2  IS

  CONTADOR   NUMBER;
 VSALIDA    varchar2(300);
 VDESC       varchar2(30);
 VDESC2     NUMBER:=0;
 VCOSTO     NUMBER;
 VCOSTO2    NUMBER;
 vrango1    number;
 vrango2    number;
 vparam_mate    NUMBER;
 VTALLERES    NUMBER:=0;
 vcampus      varchar2(4);
 VFUNCION     varchar2(40);
 PACAMPUS     VARCHAR2(4);
 TERMATERIAS  VARCHAR2(10);
 VDESC_MAT_INGLES VARCHAR2(70):= 'NA';

/* esta funcion regresa las materias reprobadas por alumno para nivelaciones en ingles.
el accesorios es NIVG.     glovicx 03.11.022
*/

BEGIN


         DELETE FROM extraor2
         WHERE  PIDM = PPIDM ;

--------------------aqui determinamos si el campus es unica o es utel glovicx 23/11/2020
begin
select CAMPUS
   into vcampus
 from tztprog
   where pidm  = PPIDM
   and programa = pprogram
 ;

 exception when others then
  vcampus := null;

 end;


-- nuevo aqui buscamos el nuevo valor del periodo en shgrade glovicx 17/01/022

      begin
         select distinct ZSTPARA_PARAM_DESC
           INTO TERMATERIAS
        from ZSTPARA
        where 1=1
        and ZSTPARA_MAPA_ID = 'ESC_SHAGRD'
        and ZSTPARA_PARAM_ID = substr(F_GetSpridenID(PPIDM),1,2);
      exception when others then
          TERMATERIAS := null;

       end;


--insert into twpaso ( valor1, valor2 )
 --     values('paso universidad fuera materisa',VSALIDA );

------aqui evalua a donde entra para sacar las materias-- glovicx 23/11/20


FOR JUMP IN (
        select distinct datos.materia MATERIA, --||'|'||costo,
        rpad(cc.SCRSYLN_LONG_COURSE_TITLE,40,'-') NOMBRE_MATERIA, --||' $ '|| costo,
        datos.programa AS PROGRAMA,
        -- nvl(datos.costo, 000)as costo,
        DATOS.PIDM AS PIDM
        ,datos.nivel as nivel
        ,datos.sp
        ,DATOS.CAMPUS
        from (
                SELECT (qq.ssbsect_subj_code || qq.ssbsect_crse_numb) materia
                --( select M.SZTMACO_MATPADRE from sztmaco m where M.SZTMACO_MATHIJO = qq.SSBSECT_SUBJ_CODE || qq.SSBSECT_CRSE_NUMB) materia,
                , CASE
                WHEN qq.ssbsect_seq_numb IS NULL
                THEN
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                ELSE
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || SSBSECT_CRSE_TITLE
                END nombre_materia,
                so.SORLCUR_PROGRAM as programa
                ,SO.SORLCUR_PIDM as pidm
                ,SO.SORLCUR_LEVL_CODE AS NIVEL
                ,'1' FINAL
                ,cr.SFRSTCR_STSP_KEY_SEQUENCE as Sp
                ,SO.SORLCUR_CAMP_CODE  AS CAMPUS
                FROM ssbsect qq, sfrstcr cr, shrgrde sh, sorlcur so, stvterm x, spriden sp
                ,(SELECT ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_ID, ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION' ) cos
                WHERE 1=1
                AND cr.sfrstcr_pidm = PPIDM
                AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                AND cr.sfrstcr_crn = qq.ssbsect_crn
                AND sh.shrgrde_code = cr.SFRSTCR_GRDE_CODE
                and sh.SHRGRDE_LEVL_CODE = cr.SFRSTCR_LEVL_CODE
                AND sh.shrgrde_passed_ind = 'N'
                and cr.SFRSTCR_GRDE_CODE is not null
                AND so.SORLCUR_LMOD_CODE = 'LEARNER'
                AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS')
                AND sh.shrgrde_levl_code = so.SORLCUR_LEVL_CODE
                AND cr.sfrstcr_pidm = so.sorlcur_pidm
                And so.sorlcur_program = pprogram
                And cr.SFRSTCR_STSP_KEY_SEQUENCE = so.SORLCUR_KEY_SEQNO
                AND so.sorlcur_term_code = x.stvterm_code
                AND sp.spriden_change_ind IS NULL
                and cr.sfrstcr_pidm = SP.SPRIDEN_PIDM
                and cos.ZSTPARA_PARAM_DESC(+) = qq.ssbsect_subj_code || qq.ssbsect_crse_numb
                minus
                SELECT qq.ssbsect_subj_code || qq.ssbsect_crse_numb materia
                , CASE
                WHEN qq.ssbsect_seq_numb IS NULL
                THEN
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                ELSE
                SUBSTR (x.stvterm_desc, 1, 6) || '-' || qq.SSBSECT_CRSE_TITLE
                END nombre_materia,
                so.SORLCUR_PROGRAM as programa
                ,SO.SORLCUR_PIDM as pidm
                ,SO.SORLCUR_LEVL_CODE AS NIVEL
                ,'2' FINAL
                ,cr.SFRSTCR_STSP_KEY_SEQUENCE as Sp
                  ,SO.SORLCUR_CAMP_CODE  AS CAMPUS
                FROM ssbsect qq, sfrstcr cr, sorlcur so, stvterm x, spriden sp
                ,(SELECT ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_ID, ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION' ) cos
                WHERE 1=1
                AND cr.sfrstcr_pidm = PPIDM --fget_pidm('010075696')
                AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                AND cr.sfrstcr_crn = qq.ssbsect_crn
                and cr.SFRSTCR_GRDE_CODE is null
                and cr.SFRSTCR_RSTS_CODE = 'RE'
                AND so.SORLCUR_LMOD_CODE = 'LEARNER'
                AND so.SORLCUR_LEVL_CODE IN ('LI', 'MA', 'MS')
                AND cr.sfrstcr_pidm = so.sorlcur_pidm
                And so.sorlcur_program = pprogram
                AND so.sorlcur_term_code = x.stvterm_code
                AND sp.spriden_change_ind IS NULL
                and cr.sfrstcr_pidm = SP.SPRIDEN_PIDM
                And cr.SFRSTCR_STSP_KEY_SEQUENCE = so.SORLCUR_KEY_SEQNO
                and cos.ZSTPARA_PARAM_DESC(+) = qq.ssbsect_subj_code || qq.ssbsect_crse_numb
                ) datos
               , SCRSYLN cc
                where 1=1
                and SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB = datos.materia
                --AND SCBCRSE_CSTA_CODE = 'A'
                AND NOT EXISTS
                (SELECT 1
                FROM SVRSVPR p, SVRSVAD h
                WHERE p.SVRSVPR_SRVC_CODE = 'NIVG'
                AND P.SVRSVPR_PIDM = PPIDM --fget_pidm('010075696')
                AND p.SVRSVPR_SRVS_CODE in ('AC')--se quito la validacion de "PA" a peticion de Fernando el dia 05/12/2019
                AND h.SVRSVAD_PROTOCOL_SEQ_NO = p.SVRSVPR_PROTOCOL_SEQ_NO
                --AND h.SVRSVAD_ADDL_DATA_CDE = datos.materia||'|'||costo) ----con este filtra que no se solicite una materia que ya fue solicitada
                --AND substr(h.SVRSVAD_ADDL_DATA_CDE,1,instr(h.SVRSVAD_ADDL_DATA_CDE,'|',1)-1) = datos.materia)
                and h.SVRSVAD_ADDL_DATA_CDE = datos.materia)
                and datos.materia NOT in ( select SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB
                        FROM ssbsect qq, sfrstcr cr, shrgrde SH
                        WHERE 1=1
                        AND cr.sfrstcr_pidm = PPIDM --fget_pidm('010075696')
                        AND cr.sfrstcr_term_code =qq.ssbsect_term_code
                        AND cr.sfrstcr_crn = qq.ssbsect_crn
                         and  SHRGRDE_TERM_CODE_EFFECTIVE   = TERMATERIAS
                        and ( cr.SFRSTCR_GRDE_CODE in ('6.0','7.0','8.0','9.0','10.0')
                        or cr.SFRSTCR_GRDE_CODE is null )
                        AND CR.SFRSTCR_GRDE_CODE = SH.SHRGRDE_CODE
                        AND CR.SFRSTCR_LEVL_CODE = SH.SHRGRDE_LEVL_CODE
                        AND shrgrde_passed_ind = 'Y' ---------ESTO DIVIDE LAS CALIFICACIONES EN PASADAS Y REPROBADAS PARA LI Y MA.MS
                        and cr.sfrstcr_term_code = (select max(cr.sfrstcr_term_code ) from sfrstcr c2 where cr.sfrstcr_pidm = c2.sfrstcr_pidm ))
                And (DATOS.PIDM, datos.materia ) not in (select a.SFRSTCR_PIDM, b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB
                                                                                            from sfrstcr a, ssbsect b
                                                                                            Where  a.SFRSTCR_TERM_CODE =  b.SSBSECT_TERM_CODE
                                                                                            And a.SFRSTCR_CRN = b.SSBSECT_CRN
                                                                                            And a.SFRSTCR_RSTS_CODE = 'RE'
                                                                                            and ( a.SFRSTCR_GRDE_CODE in (select SHRGRDE_CODE
                                                                                                                                from SHRGRDE
                                                                                                                                Where SHRGRDE_LEVL_CODE = a.SFRSTCR_LEVL_CODE
                                                                                                                                and  SHRGRDE_TERM_CODE_EFFECTIVE   = TERMATERIAS
                                                                                                                                And SHRGRDE_PASSED_IND ='Y')
                                                                                                 or a.SFRSTCR_GRDE_CODE is null ))
                ORDER BY 1,6
        ) LOOP
         ---------------------se obtiene el porcentaje de avance del alumno para calcular el precio
        BEGIN
           SELECT ROUND(nvl(SZTHITA_AVANCE,0))
              INTO VDESC2
                FROM SZTHITA ZT
                WHERE ZT.SZTHITA_PIDM = JUMP.PIDM
                AND    ZT.SZTHITA_LEVL  = jump.nivel
                AND   ZT.SZTHITA_PROG   = JUMP.PROGRAMA  ;
                ----dbms_output.PUT_LINE('SALIDA AVANCE HITA  '|| VDESC2);
       EXCEPTION WHEN OTHERS THEN
        VDESC2 :=0;
                BEGIN
                   SELECT ROUND(BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 ( JUMP.PIDM, JUMP.PROGRAMA ))
                          INTO VDESC2
                     FROM DUAL;

                  --   --dbms_output.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
                  EXCEPTION WHEN OTHERS THEN
                   VDESC2 :=0;
                  END;
      END;
      -------------------OBTIENE EL COSTO------------
      BEGIN
                ---se cambia la forma de calcular el costo nuevo requerimento 07/03/2022  de tavito
                 /*  select ZSTPARA_PARAM_DESC, ZSTPARA_PARAM_VALOR
                      INTO VDESC, VCOSTO
                    from  ZSTPARA
                    where ZSTPARA_MAPA_ID = 'PORCENTAJE_NIVE'
                  --  and  ZSTPARA_PARAM_ID = jump.nivel
                    and  substr(ZSTPARA_PARAM_ID,1,2) =  jump.nivel -- 'LI'
                    and  substr(ZSTPARA_PARAM_ID,4) =  jump.CAMPUS -- 'UTL'
                    and ROUND(VDESC2) between substr(ZSTPARA_PARAM_DESC,1,instr(ZSTPARA_PARAM_DESC,',',1)-1)
                    and  substr(ZSTPARA_PARAM_DESC,instr(ZSTPARA_PARAM_DESC,',',1)+1)
                    ; */
                    select distinct SZT_PRECIO
                       into VCOSTO
                        from sztnipr
                        where 1=1
                        and SZT_NIVEL =  jump.nivel
                        and SZT_CAMPUS  =  jump.CAMPUS
                        and ROUND(VDESC2) between ( SZT_MINIMO ) and (SZT_MAXIMO )
                        and substr(SZT_CODE,1,2) = substr(F_GetSpridenID(JUMP.PIDM),1,2);


                    ----dbms_output.PUT_LINE('SALIDA COSTOS_PARAMETROS  '|| VDESC ||'-'|| VCOSTO);
        EXCEPTION WHEN OTHERS THEN

          VCOSTO:= 0;
      END;


          IF  vcosto = 0  then
            begin
              SELECT  distinct nvl(MAX (svrrsso_serv_amount), 0)
                  INTO  VCOSTO2
                   FROM svrrsso a , tbbdetc tt,SVRRSRV r
                    WHERE  1=1
                      AND A.SVRRSSO_SRVC_CODE     = R.SVRRSRV_SRVC_CODE
                      and A.SVRRSSO_RSRV_SEQ_NO = R.SVRRSRV_SEQ_NO
                      and  a.svrrsso_srvc_code = 'NIVG'
                      and  a.SVRRSSO_DETL_CODE = tt.TBBDETC_DETAIL_CODE
                      AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(F_GetSpridenID(JUMP.PIDM),1,2)
                         --and  tt.TBBDETC_TAXT_CODE = jump.nivel
                      and   r.SVRRSRV_LEVL_CODE =  jump.nivel
                         ;
              EXCEPTION when others then
                    VCOSTO2 := 0;
              end;

             ELSE
             VCOSTO2 := vcosto;
          end if;

          ------excepcion especial para que los talleres los cobre de 2100 segun el parametrizador-----
         begin
           select ZSTPARA_PARAM_VALOR
             into vparam_mate
           FROM ZSTPARA
              WHERE ZSTPARA_MAPA_ID = 'MATE_NIVELACION'
               and   ZSTPARA_PARAM_ID  = JUMP.MATERIA
               AND ZSTPARA_PARAM_DESC  = JUMP.CAMPUS
            ;

          exception when others then
             vparam_mate := VCOSTO2;
          end;

          if vparam_mate > 0 then
            VCOSTO2 := vparam_mate;
            else
               VCOSTO2 := VCOSTO2 ;
          end if;
         -------------------
     ----dbms_output.put_line('salida materias::  '||JUMP.MATERIA||'-'||JUMP.NOMBRE_MATERIA||'-'||JUMP.PROGRAMA||'-'||VCOSTO2||'-'||JUMP.PIDM||'--'||jump.nivel );
      ----se agrega la validacion para EXCLUIR LAS MATERIAS DE LOS TALLERES A TRAVES DEL PARAMETRIZADOR LO HIZO FERNANDO
      -----19/03/2020  GLOVICX
           BEGIN

                select 1--* --ZSTPARA_PARAM_VALOR as alum_sin_restriccio
                  INTO VTALLERES
                 from zstpara z
                  where 1=1
                      and Z.ZSTPARA_MAPA_ID  = 'SIN_MAT_MOODLE'
                      and z.ZSTPARA_PARAM_ID = JUMP.MATERIA
                      ;
           EXCEPTION WHEN OTHERS THEN
             VTALLERES := 0;
           END;

      ------SE HACE EL TRASLATE DE LAS MATERIAS AL INGLES  GLOVICX 29.09.022
      BEGIN
        select distinct ZSTPARA_PARAM_DESC
          INTO  VDESC_MAT_INGLES
           from ZSTPARA
                where 1=1
                AND ZSTPARA_MAPA_ID = 'NIVE_GLOBAL'
                AND ZSTPARA_PARAM_VALOR = JUMP.MATERIA;


       EXCEPTION WHEN OTHERS THEN
             VDESC_MAT_INGLES := 'NA';

      END;





        IF VTALLERES >= 1  OR VDESC_MAT_INGLES = 'NA' THEN
             NULL; --AQUI LO EXCLUYO
           ELSE

                         INSERT INTO extraor2 ---------------se cambio este queri es el que presenta las materias reprobadas en el SSB -- VIC-- 28.06.2018
                          VALUES ( JUMP.MATERIA||'|'||VCOSTO2,
                                   VDESC_MAT_INGLES ||' $ '||TO_CHAR(VCOSTO2,'999,999.00' ),
                                   JUMP.PROGRAMA,
                                   VCOSTO2,
                                   JUMP.PIDM);
                 COMMIT;
            END IF;

   END LOOP;


    VSALIDA   := 'EXITO';
    RETURN   VSALIDA;

Exception
            When others  then
            -----   vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
       VSALIDA:='Error :'||sqlerrm;
    -- insert into twpasow(valor1, valor2, valor3, valor6)
    ---   values( 'eroorro en fmateria_nive gral ',TO_CHAR(VCOSTO2,'L99G999D99MI' ),PPIDM,VSALIDA  );
    RETURN (VSALIDA);


END F_MATERIA_NIVE_INGLES;

FUNCTION   f_inserta_horario_nivg ( ppidm number,  pcode varchar2,  PSEQ_NO NUMBER ) return varchar2
IS
-----se debe insertar siempre el horario del alumno para la nivelacio. si paga en linea ya esta cagado el horario
-- pero si no paga y se cancela entonces se borra el horario ..
--glovicx 27/06/2019-----
/* Formatted on 27/06/2019 01:55:34 p.m. (QP5 v5.215.12089.38647) */
schd        VARCHAR2(10):= NULL;
title       VARCHAR2(90):= NULL;
credit       NUMBER;  -- VARCHAR2(10):= NULL;
gmod        VARCHAR2(40):=NULL;
f_inicio    VARCHAR2(16):=NULL;
f_fin       VARCHAR2(16):=NULL;
sem         VARCHAR2(10):=NULL;
crn         VARCHAR2(10):= NULL;
pidm_prof   VARCHAR2(14):= '019852882';  -------QUITAR DESPUES DE LAS PRUEBAS
credit_bill  NUMBER  ; --VARCHAR2(10):= NULL;
vl_exite_prof NUMBER:=0;
V_SEQ_NO     NUMBER:=0;
vpparte      VARCHAR2(5);
VMATERIA     VARCHAR2(14);
Vnivel       VARCHAR2(4);
Vgrupo       VARCHAR2(3):='01';
Vsubj        VARCHAR2(5);
Vcrse        VARCHAR2(5);
conta_ptrm   NUMBER:=0;
Vstudy        NUMBER:=0;
VPROGRAMA     VARCHAR2(14);
pidm_prof2    number:=0;
cssrmet      number:=0;
csirasgn     number:=0;
VSALIDA      VARCHAR2(5000):='EXITO';
VNSFRST      NUMBER:=0;
vno_orden     number:=0;
NO_ORDEN_OLD   NUMBER:=0;
VFINI2          VARCHAR2(14);
VFFIN2          VARCHAR2(14);
Vperiodo       VARCHAR2(20);
vcampus      varchar2(4);

begin

IF PCODE = 'NIVG' THEN
null;


-----------------------NSERTA TABLA DE PASO PARA PRUEBA S----------------------

-- --dbms_output.put_line('INICIO :1::  '||Ppidm ||'-'|| PSEQ_NO||'-'||PPERIODO ||'-'||PCODE );
    schd := null;
    title := null;
    credit := null;
    gmod :=null;
    f_inicio :=null;
    f_fin :=null;
    sem :=null;
    crn := null;
    pidm_prof := null;
    vl_exite_prof :=0;
    vpparte     := '';
        -- INSERT INTO TWPASOW (VALOR1, VALOR2, VALOR3, VALOR4, VALOR5, VALOR6, VALOR7)
        --VALUES ('f_INSERTA_HORARIO_PARAM DE INICIO', ppidm ,  pcode , Vperiodo , Vcampus , PSEQ_NO, SYSDATE  );COMMIT;
                           BEGIN
                          select V.SVRSVPR_PROTOCOL_SEQ_NO
                                 , case  when INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1) > 0 then
                                      --SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1)
                                      SVRSVAD_ADDL_DATA_CDE
                                       else
                                      --SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10)-1 )
                                      SVRSVAD_ADDL_DATA_CDE
                                  end as materia
                                INTO V_SEQ_NO, vmateria
                             from svrsvpr v,SVRSVAD VA
                                    where SVRSVPR_SRVC_CODE = pcode
                                       AND  SVRSVPR_PIDM   = ppidm
                                        AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PSEQ_NO
                                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                       and va.SVRSVAD_ADDL_DATA_SEQ in ( 2) ; ------el valor 2 es para la materia
                         EXCEPTION WHEN OTHERS THEN
                           VMATERIA :='';
                           V_SEQ_NO := 0;
                           VSALIDA  := SQLERRM;
                         END;

                          ----dbms_output.put_line('RECUPERA LA MATERIA DE NIVE::'|| vmateria);
                             --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('PASOWWW_SIU_MATERIA ',Ppidm, PSEQ_NO,vmateria, SUBSTR(vl_error,1,100), sysdate);

                          BEGIN
                            select V.SVRSVPR_PROTOCOL_SEQ_NO
                                 , case  when INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1) > 0 then
                                      SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1)-1)
                                       else
                                      SUBSTR(SVRSVAD_ADDL_DATA_CDE,1, decode(INSTR(SVRSVAD_ADDL_DATA_CDE,'|',1),0,10)-1 )
                                  end as PPARTE
                                 INTO V_SEQ_NO, vpparte
                               from svrsvpr v,SVRSVAD VA
                                    where SVRSVPR_SRVC_CODE = pcode
                                       AND  SVRSVPR_PIDM   = ppidm
                                        AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PSEQ_NO
                                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                       and va.SVRSVAD_ADDL_DATA_SEQ in (7) ; ------el valor 2 es para la parte de periodo
                         EXCEPTION WHEN OTHERS THEN
                           VPPARTE :='';
                           V_SEQ_NO := 0;
                           VSALIDA  := SQLERRM;
                         END;
                          --dbms_output.put_line('RECUPERA LA PARTE PERIODO DE NIVE::'|| vpparte);
                              -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 )
                              -- VALUES ('PASOWWW_SIU_PPARTEP ',Ppidm, PSEQ_NO,vpparte, SUBSTR(vl_error,1,100),sysdate);

                        BEGIN
                            select V.SVRSVPR_PROTOCOL_SEQ_NO ,
                               SVRSVAD_ADDL_DATA_CDE  PROG,SVRSVPR_CAMP_CODE
                                 INTO V_SEQ_NO, VPROGRAMA, VCAMPUS
                               from svrsvpr v,SVRSVAD VA
                                    where SVRSVPR_SRVC_CODE = pcode
                                       AND  SVRSVPR_PIDM   = ppidm
                                       AND V.SVRSVPR_PROTOCOL_SEQ_NO  =  PSEQ_NO
                                       and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                                       and va.SVRSVAD_ADDL_DATA_SEQ in ( 1) ; ------el valor1 es programa
                         EXCEPTION WHEN OTHERS THEN
                           VPROGRAMA :='';
                           V_SEQ_NO := 0;
                           VSALIDA  := SQLERRM;
                         END;
                   -------como ya no hay periodo ahora sacamos de la parte del periodo selecionado
                   ------obtenemos el rango de fechas ini y fin
         begin
                select substr(rango,1, instr(rango,'-TO-',1 )-1)as fecha_ini
                        ,substr(rango,instr(rango,'-TO-',1 )+4)as fecha_fin
                        INTO VFINI2, VFFIN2
                from (
                select   --substr(SVRSVAD_ADDL_DATA_DESC,33  )  rango
                      SVRSVAD_ADDL_DATA_DESC  rango
                         from svrsvpr v,SVRSVAD VA
                            where SVRSVPR_SRVC_CODE = pcode
                            AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQ_NO
                              AND  SVRSVPR_PIDM    = ppidm
                               and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
                               and va.SVRSVAD_ADDL_DATA_SEQ = '7' --- ES EL MISMO DEL PARTE DE PERIODO
                               ) ;

          EXCEPTION WHEN OTHERS  THEN
            VFINI2:= TRUNC(SYSDATE);
            VFFIN2 := TRUNC(SYSDATE)+7;
          END;
         -------CON LA FECHAS BUSCAMOS EL PERIODO Y LO CALCULAMOS


            Begin

             select SOBPTRM_TERM_CODE
                into Vperiodo
                from sobptrm
                where 1=1
                and  sobptrm_ptrm_code   = TRIM(vpparte)
                AND TRUNC(SOBPTRM_START_DATE) >=  TO_CHAR(to_date(VFINI2,'MM/dd/YYYY') , 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH')
                AND TRUNC(SOBPTRM_END_DATE)  <=    TO_CHAR(to_date(VFFIN2,'MM/dd/YYYY') , 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH')
                 and  substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2)
                ;

            Exception
            When Others then
              BEGIN
                    select DISTINCT SOBPTRM_TERM_CODE
                        into Vperiodo
                        from sobptrm
                        where 1=1
                        and  sobptrm_ptrm_code   = TRIM(vpparte)
                        AND TRUNC(SOBPTRM_START_DATE) >=  TO_CHAR(to_date(VFINI2,'MM/dd/YYYY') , 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH')
                        --AND TRUNC(SOBPTRM_END_DATE)  <=    TO_CHAR(to_date(VFFIN2,'MM/dd/YYYY') , 'DD/MM/yyyy', 'NLS_DATE_LANGUAGE = SPANISH')
                         and  substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2) ;

               EXCEPTION WHEN OTHERS THEN
                    vl_error :=  sqlerrm;
                    --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 , valor7)
                   -- VALUES ('INSRT_HORARIO_periodo_ERROORR22:: ',Ppidm, PSEQ_NO,Vperiodo||' *-* '||VPparte, VFINI2, vl_error, VFFIN2);

                    VSALIDA  := SQLERRM;
                END;

            End;

         --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 , valor7)
           --VALUES ('INSRT_HORARIO_periodo_ooookkkkk:: ',Ppidm, PSEQ_NO,Vperiodo||' *-* '||VPparte, VFINI2, vl_error, VFFIN2);
--            commit;

                      begin
                       select SCBCRSE_SUBJ_CODE, SCBCRSE_CRSE_NUMB
                         INTO VSUBJ, VCRSE
                        from scbcrse
                         where SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB = vmateria;
                         ----dbms_output.put_line('RECUPERA el SUBJ__CRSE::'|| VSUBJ||'-'||VCRSE);
                     exception when others then
                        --                       VSUBJ :=null;
                          --                     VCRSE :=null;
                          -----dbms_output.put_line('RECUPERA el SUBJ__CRSE:antes:'|| VSUBJ||'-'||VCRSE);
                        if  length(vmateria) = 9  then
                             VSUBJ :=SUBSTR(vmateria,1,4);
                             VCRSE :=SUBSTR(vmateria,5,5);

                       elsif  length(vmateria) = 8  then
                             VSUBJ :=SUBSTR(vmateria,1,4);
                             VCRSE :=SUBSTR(vmateria,5,4);

                            ELSE
                               VSUBJ :=SUBSTR(vmateria,1,3);
                               VCRSE :=SUBSTR(vmateria,4,4);
                       end if;

                      -- VSALIDA  := SQLERRM;
                       ----dbms_output.put_line('RECUPERA el SUBJ__CRSE222::'|| VSUBJ||'-'||VCRSE);
                     end;

                           Begin
                             select scrschd_schd_code, scbcrse_title, scbcrse_credit_hr_low, SCBCRSE_BILL_HR_LOW
                                into schd, title, credit, credit_bill
                                 from scbcrse, scrschd
                                where scbcrse_subj_code||scbcrse_crse_numb = TRIM(vmateria)
                                 and     scbcrse_eff_term='000000'
                                 and     SCBCRSE_CSTA_CODE  = 'A'
                                 and     scrschd_subj_code=scbcrse_subj_code
                                 and     scrschd_crse_numb=scbcrse_crse_numb
                                 and     scrschd_eff_term=scbcrse_eff_term;
                           Exception
                            When Others then
                                  schd := null;
                                  title := null;
                                  credit := null;
                                  credit_bill :=null;
                                   ----dbms_output.PUT_LINE('EEEERRRROOOR DEL CREDITOS Y MAS :: '|| VSUBJ||'-'||VCRSE);
                                   VSALIDA  := SQLERRM;
                           End;

                       -----dbms_output.PUT_LINE('SALIDA DEL CREDITOS Y MAS :: '|| schd||'-'|| title||'-'||credit||'-'||credit_bill );
                        --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_CREDITOS ',Ppidm, PSEQ_NO,schd||'-'||title, SUBSTR(vl_error,1,100), sysdate);
                            begin
                                select scrgmod_gmod_code
                                      into gmod
                                from scrgmod
                                where scrgmod_subj_code||scrgmod_crse_numb=VMATERIA
                                and     scrgmod_default_ind='D';
                            exception when others then
                                gmod:='1';
                               -- VSALIDA  := SQLERRM;
                            end;
                              ----dbms_output.PUT_LINE('SALIDA D GMOD CODE :: '|| gmod );
                      BEGIN

                       SELECT DISTINCT SMRPRLE_LEVL_CODE
                       INTO VNIVEL
                       FROM SMRPRLE
                       WHERE SMRPRLE_PROGRAM = VPROGRAMA;

                      EXCEPTION WHEN OTHERS THEN
                      VNIVEL :='';
                      VSALIDA  := SQLERRM;
                      END;
                         ----dbms_output.PUT_LINE('SALIDA D NIVEL :: '|| VNIVEL );
                        ---------------------aqui va la validacion de si ya existe el horario entoces hace la compactacion de grupos o no?---
                         begin                  ---- validacion UNO ver si existe el CRN creado para esa materia,parteperiod,periodo en gral
                            SELECT SSBSECT_CRN
                            into CRN
                                FROM SSBSECT
                                WHERE 1=1
                                --and SSBSECT_CRN = 'A9'
                                AND   SSBSECT_TERM_CODE = vPERIODO
                                and   SSBSECT_PTRM_CODE = vpparte
                                and   SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB = vmateria ;

                                null;
                         exception when others then
                         null;
                         crn := null;

                         --VSALIDA  := SQLERRM;
                         end;

                    conta_ptrm :=0;
                   ----dbms_output.put_line('salida 21  '||PPIDM ||'-'|| VPROGRAMA );
                        Begin
                             select count(*)
                                into conta_ptrm
                             from sfbetrm
                             where sfbetrm_term_code=vPERIODO
                             and     sfbetrm_pidm=PPIDM;
                        Exception
                            When Others then
                              conta_ptrm := 0;
                            --  VSALIDA  := SQLERRM;
                        End;


                         if conta_ptrm =0 then
                                Begin
                                        insert into sfbetrm values(vPERIODO, PPIDM, 'EL', sysdate, 99.99, 'Y', null, sysdate, sysdate, null,null,null,null,'WWW_SIU', null,'WWW_SIU', null, 0,null,null, null,null,user,PSEQ_NO);
                                Exception
                                When Others then
                                    VSALIDA  := ('Se presento un error al insertar en la tabla sfbetrm ' || sqlerrm);
                                 --  insert into twpasow(valor1,valor2,valor3,valor4, valor5) values('ERROR_inserta_sfbetrm::1: ',pidm_prof2,PPERIODO,crn, sysdate );commit;
                                End;
                         end if;

                         ------------------------  primer caso el CRN ya existe es decir ya se abrio un grupo para ese periodo, parte de per y materia
                         ---------------hay que utilizar ese grupo para todos los alumnos que pidan nivelacion con las mismas caracteristicas.
                         ----------------solo hay que crear el horario en sfrstrc  con el estatus de la materia RE.
                IF CRN is not null  then
                  ----------------------------ahora valida si esta esta insertado el regs para ese alumno pero tiene estatus dd
                  ----------------------------si es correcto entonces solo cambia el estatus a RE....si, no lo inserta
                              -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 )
                               --VALUES ('PASOWWW_SIU_CRN_V1 ',Ppidm, PSEQ_NO,schd||'-'||title, SUBSTR(vl_error,1,100), CRN);
                            BEGIN
                                  SELECT COUNT(1)
                                    INTO VNSFRST
                                    FROM SFRSTCR  F
                                    WHERE  F.SFRSTCR_CRN     = CRN
                                    AND F.SFRSTCR_TERM_CODE  = vPERIODO
                                    AND F.SFRSTCR_PIDM       = PPIDM
                                    and F.SFRSTCR_PTRM_CODE  = vpparte ;

                             EXCEPTION WHEN OTHERS THEN
                             VNSFRST := 0;
                             END;

                  IF VNSFRST = 0  THEN  ----------como este alumno no a sido  insertado entonces lo hacemos

                               Begin
                                     select distinct max(sorlcur_key_seqno)
                                            into Vstudy
                                      from sorlcur
                                        where sorlcur_pidm        = PPIDM
                                        and     sorlcur_program   = VPROGRAMA
                                        and     sorlcur_lmod_code = 'LEARNER'
                                     --   AND     SORLCUR_CACT_CODE = 'ACTIVE'     ---- se quita filtro por Vic ramirez esto por que los alumnos que estan de baja y quieran una nivelacion no estan activos
                                        and     sorlcur_term_code = (select max(sorlcur_term_code) from sorlcur
                                                                        where   sorlcur_pidm=PPIDM
                                                                        and     sorlcur_program=VPROGRAMA
                                                                        and     sorlcur_lmod_code='LEARNER'
                                                                         --AND     SORLCUR_CACT_CODE = 'ACTIVE'---- se quita filtro por Vic ramirez esto por que los alumnos que estan de baja y quieran una nivelacion no estan activos
                                                                         )
                                        ;
                               Exception
                               when Others then
                                  Vstudy := null;
                                  VSALIDA  := 'Se presento un error al obtener la informacion de SORLCUR-key_seq_no ' ||PPIDM||'-'||  VPERIODO  ||'*'||crn|| sqlerrm;
                               End;

                                                Begin
                                                --   --dbms_output.put_line('Salida inserta sfrsctcr  21-D :'||PPIDM||'-'||  PPERIODO  ||'*'||crn||'*'|| Vgrupo||'*'||VPparte||'*'||credit_bill||'*'||credit||'*'||gmod||'*'||Pcampus);
                                                 -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , valor7)
                                                 -- VALUES ('COMPACTA_GRUPOS_INSRT_SFRSTCR--00 ',Ppidm, PSEQ_NO,Vperiodo,crn, sysdate, SUBSTR(VSALIDA,1,500));

                                                    insert into sfrstcr values(
                                                                            VPERIODO,     --SFRSTCR_TERM_CODE
                                                                            Ppidm,     --SFRSTCR_PIDM
                                                                            crn,     --SFRSTCR_CRN
                                                                            1,     --SFRSTCR_CLASS_SORT_KEY
                                                                            Vgrupo,    --SFRSTCR_REG_SEQ
                                                                            VPparte,    --SFRSTCR_PTRM_CODE
                                                                            'RE',     --SFRSTCR_RSTS_CODE
                                                                            sysdate,    --SFRSTCR_RSTS_DATE
                                                                            null,    --SFRSTCR_ERROR_FLAG
                                                                            null,    --SFRSTCR_MESSAGE
                                                                            credit_bill,    --SFRSTCR_BILL_HR
                                                                            3, --SFRSTCR_WAIV_HR
                                                                            credit,     --SFRSTCR_CREDIT_HR
                                                                            credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                                                            credit,     --SFRSTCR_CREDIT_HR_HOLD
                                                                            gmod,     --SFRSTCR_GMOD_CODE
                                                                            null,    --SFRSTCR_GRDE_CODE
                                                                            null,    --SFRSTCR_GRDE_CODE_MID
                                                                            null,    --SFRSTCR_GRDE_DATE
                                                                            'N',    --SFRSTCR_DUPL_OVER
                                                                            'N',    --SFRSTCR_LINK_OVER
                                                                            'N',    --SFRSTCR_CORQ_OVER
                                                                            'N',    --SFRSTCR_PREQ_OVER
                                                                            'N',     --SFRSTCR_TIME_OVER
                                                                            'N',     --SFRSTCR_CAPC_OVER
                                                                            'N',     --SFRSTCR_LEVL_OVER
                                                                            'N',     --SFRSTCR_COLL_OVER
                                                                            'N',     --SFRSTCR_MAJR_OVER
                                                                            'N',     --SFRSTCR_CLAS_OVER
                                                                            'N',     --SFRSTCR_APPR_OVER
                                                                            'N',     --SFRSTCR_APPR_RECEIVED_IND
                                                                            sysdate,      --SFRSTCR_ADD_DATE
                                                                            sysdate,     --SFRSTCR_ACTIVITY_DATE
                                                                            Vnivel,     --SFRSTCR_LEVL_CODE
                                                                            vcampus,     --SFRSTCR_CAMP_CODE
                                                                            vmateria,     --SFRSTCR_RESERVED_KEY
                                                                            null,     --SFRSTCR_ATTEND_HR
                                                                            'Y',     --SFRSTCR_REPT_OVER
                                                                            'N' ,    --SFRSTCR_RPTH_OVER
                                                                            null,    --SFRSTCR_TEST_OVER
                                                                            'N',    --SFRSTCR_CAMP_OVER
                                                                            'WWW_SIU',    --SFRSTCR_USER
                                                                            'N',    --SFRSTCR_DEGC_OVER
                                                                            'N',    --SFRSTCR_PROG_OVER
                                                                            null,    --SFRSTCR_LAST_ATTEND
                                                                            null,    --SFRSTCR_GCMT_CODE
                                                                            'WWW_SIU',    --SFRSTCR_DATA_ORIGIN
                                                                            sysdate,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                                            'N',  --SFRSTCR_DEPT_OVER
                                                                            'N',  --SFRSTCR_ATTS_OVER
                                                                            'N', --SFRSTCR_CHRT_OVER
                                                                            null, --SFRSTCR_RMSG_CDE
                                                                            null,  --SFRSTCR_WL_PRIORITY
                                                                            null,  --SFRSTCR_WL_PRIORITY_ORIG
                                                                            null,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                                            null, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                                            'N', --SFRSTCR_MEXC_OVER
                                                                            Vstudy,--SFRSTCR_STSP_KEY_SEQUENCE
                                                                            null,--SFRSTCR_BRDH_SEQ_NUM
                                                                            '01',--SFRSTCR_BLCK_CODE
                                                                            null,--SFRSTCR_STRH_SEQNO
                                                                            PSEQ_NO, --SFRSTCR_STRD_SEQNO
                                                                            null,  --SFRSTCR_SURROGATE_ID
                                                                            null, --SFRSTCR_VERSION
                                                                            'WWW_SIU',--SFRSTCR_USER_ID
                                                                            null );--SFRSTCR_VPDI_CODE
                                                 EXCEPTION WHEN OTHERS THEN
                                                   VSALIDA  := 'error ' ||sqlerrm;
                                                   --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , valor7) VALUES ('EERR_COMPACTA_GRUPOS_INSRT_SFRSTCR ',Ppidm, PSEQ_NO,Pperiodo,crn, sysdate, SUBSTR(VSALIDA,1,500));
                                                 end ;

                                        --   --dbms_output.put_line('DESPUES de insert stfrscr ' || PPIDM||'-'||PPERIODO||'-'|| crn|| Vgrupo||'-'||  VPparte||'  EXEX'  );
                                                        -- vl_error  :=  'SI INSERTA SFRSTCR OK ';
                                     --   INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , valor7) VALUES ('YAAAA  COMPACTA_GRUPOS_INSRT_SFRSTCR ',Ppidm, PSEQ_NO,Pperiodo,crn, sysdate, SUBSTR(VSALIDA,1,500));
                                      --  commit;
                                            --------SEGUNDA PARTE ACTUALIZA LOS ASIENTOS O CUPOS POR MATERIA----

                                    Begin
                                         update ssbsect SB
                                                set SB.ssbsect_enrl = SB.ssbsect_enrl + 1
                                          where SB.SSBSECT_TERM_CODE = VPERIODO
                                          And  SB.SSBSECT_CRN  = crn
                                          AND  SB.SSBSECT_PTRM_CODE = VPparte  ;
                                    Exception
                                    When Others then
                                    VSALIDA  := 'Se presento un error al actualizar el enrolamiento ' ||sqlerrm;
                                    End;

                                    Begin
                                            update ssbsect
                                                set ssbsect_seats_avail=ssbsect_seats_avail -1
                                            where SSBSECT_TERM_CODE = VPERIODO
                                             And  SSBSECT_CRN  = crn
                                             AND  SSBSECT_PTRM_CODE = VPparte ;
                                    Exception
                                    When Others then
                                        VSALIDA  := 'Se presento un error al actualizar la disponibilidad del grupo ' ||sqlerrm;
                                    End;

                                    Begin
                                             update ssbsect
                                                    set ssbsect_census_enrl=ssbsect_enrl
                                             Where SSBSECT_TERM_CODE = VPERIODO
                                             And   SSBSECT_CRN  = crn
                                              AND  SSBSECT_PTRM_CODE = VPparte ;
                                    Exception
                                    When Others then
                                        VSALIDA  := 'Se presento un error al actualizar el Censo del grupo ' ||sqlerrm;
                                    End;
                  ELSE ----SI EXISTE EL MISMO ALUMNO CON L MATERIA Y TODO IGUAL ENTONCES SOLO AJUSTAMOS EL ESTATUS A "RE"

                   UPDATE SFRSTCR  F
                     SET SFRSTCR_RSTS_CODE = 'RE',
                      SFRSTCR_ACTIVITY_DATE = SYSDATE,
                      SFRSTCR_STRD_SEQNO    = PSEQ_NO
                    WHERE  F.SFRSTCR_CRN     = CRN
                   AND F.SFRSTCR_TERM_CODE  = VPERIODO
                  AND F.SFRSTCR_PIDM       = PPIDM
                  and F.SFRSTCR_PTRM_CODE  = vpparte ;
                   VSALIDA := 'EXITO';

                        --NSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 )
                        --VALUES ('aCTUALIZALOS_GRUPOS_UPDATE_SFRSTCR ',Ppidm, PSEQ_NO,Vperiodo,sysdate, SUBSTR(vl_error,1,500));
                      --  commit ;
                 END IF; -------HASTA AQUI TERMINA EL PRIMER Y SEGUNDO CASO SI YA EXISTE CRN ES LA COMPACTACION DE GRUPOS

            ELSE   -------QUIERE DECIR QUE TODO ES NUEVO E INSERTA TODO DESDE CERO---------
                         --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 )
                         --VALUES ('PASOWWW_SIU_INICIO2 ',Ppidm, PSEQ_NO,VNIVEL, SUBSTR(vl_error,1,100), sysdate);

                    VSALIDA:='EXITO';  --- se reinicia la variable ya que esta entrando en otro proceso y deber ser valor  inicial null

                         begin
                             BEGIN


                                    select sztcrnv_crn
                                    into crn
                                    from SZTCRNV
                                    where 1 = 1
                                    and rownum = 1
                                    and sztcrnv_crn not in (select to_number(crn)
                                                            from
                                                            (
                                                            select case when
                                                                substr(SSBSECT_CRN,1,1) in('L','M','A','N') then to_number(substr(SSBSECT_CRN,2,10))
                                                               else
                                                                 to_number(SSBSECT_CRN)
                                                              end crn,
                                                               SSBSECT_CRN
                                                             from ssbsect
                                                              where 1 = 1
                                                              and ssbsect_term_code= Vperiodo
                                                            )
                                            where 1 = 1)
                                    order by 1;

                                EXCEPTION WHEN OTHERS THEN
                                raise_application_error (-20002,'Error al 2 '|| SQLCODE||' Error: '||SQLERRM);
                                ----dbms_output.put_line(' error en crn 2 '||sqlerrm);
                                crn := NULL;
                                VSALIDA  := SQLERRM;
                                END;

                                  ----dbms_output.PUT_LINE('SALIDA De CRN :: '|| CRN );
                                   -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 )
                                   -- VALUES ('PASOWWW_SIU_CRN ',Ppidm, PSEQ_NO,CRN, SUBSTR(vl_error,1,100),CRN);
                                if Vnivel ='LI' then
                                crn:='L'||crn;

                                elsif  Vnivel ='MA' then
                                crn:='M'||crn;

                                elsif  Vnivel ='MS' then
                                crn:='A'||crn;

                                elsif  Vnivel ='DO' then
                                crn:='O'||crn;
                                end if;

                              Exception
                                    When Others then
                                    crn := null;
                                    VSALIDA  := SQLERRM;
                          End;

                         --   --dbms_output.PUT_LINE('SALIDA D CRN COMPUESTO :: '|| CRN );
                           ----dbms_output.PUT_LINE('SALIDA D FECHAS_INI_FIN :: '|| Vperiodo||'-'||VPparte );
                       --     INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('INSRT_HORARIO_FECHAS_antes22',Ppidm, PSEQ_NO,Pperiodo||'-'||VPparte, SUBSTR(vl_error,1,100), sysdate);
                             Begin

                               -- select distinct sobptrm_start_date, sobptrm_end_date, sobptrm_weeks
                               select distinct TO_CHAR(sobptrm_start_date, 'DD/MM/YYYY') , TO_CHAR(sobptrm_end_date, 'DD/MM/YYYY') , sobptrm_weeks
                                into f_inicio, f_fin, sem
                                from sobptrm
                                where sobptrm_term_code  =Vperiodo
                                and     sobptrm_ptrm_code=VPparte
                                and substr(SOBPTRM_TERM_CODE,1,2)   = substr(F_GetSpridenID(Ppidm),1,2);
                             Exception
                             When Others then
                                vl_error := 'No se Encontro fecha ini/ffin para el Periodo= ' ||Vperiodo ||' y Parte de Periodo= '||VPparte ||sqlerrm;
                              --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5,valor6 ) VALUES ('INSRT_HORARIO_FECHAS_ERROORR22:: ',Ppidm, PSEQ_NO,Pperiodo||'-'||VPparte, SUBSTR(vl_error,1,200), sysdate);
                              VSALIDA  := SQLERRM;
                             End;
                             -- --dbms_output.PUT_LINE('SALIDA D FECHAS_INI_FIN :: '|| f_inicio||'-'||f_fin );
                            -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 ) VALUES ('PASOWWW_SIU_FECHAS22',Ppidm, PSEQ_NO,F_INICIO||'-'||F_FIN, SUBSTR(vl_error,1,200), sysdate);
                        If crn is not null then
                                  Begin

                                   ----dbms_output.put_line('Salida  20-A :'|| Vperiodo  ||'*'||crn||'*'|| VPparte||'*'||Vgrupo||'*'||schd||'*'||Vsubj||'**'||Vcrse   );
                                    -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 )
                                    -- VALUES ('PASOWWW_SIU_ssbsect22',Ppidm, PSEQ_NO,F_INICIO||'-'||F_FIN, SUBSTR(vl_error,1,100), sysdate);

                                     ------
                                        Insert into ssbsect values (
                                                                            Vperiodo,     --SSBSECT_TERM_CODE
                                                                            crn,     --SSBSECT_CRN
                                                                            VPparte,     --SSBSECT_PTRM_CODE
                                                                            Vsubj,     --SSBSECT_SUBJ_CODE
                                                                            Vcrse,     --SSBSECT_CRSE_NUMB
                                                                            Vgrupo,     --SSBSECT_SEQ_NUMB
                                                                            'A',    --SSBSECT_SSTS_CODE
                                                                             schd,    --SSBSECT_SCHD_CODE
                                                                             vcampus,    --SSBSECT_CAMP_CODE
                                                                             title,   --SSBSECT_CRSE_TITLE
                                                                             credit,   --SSBSECT_CREDIT_HRS
                                                                             credit_bill,   --SSBSECT_BILL_HRS
                                                                             gmod,   --SSBSECT_GMOD_CODE
                                                                              null,  --SSBSECT_SAPR_CODE
                                                                              null, --SSBSECT_SESS_CODE
                                                                              null,  --SSBSECT_LINK_IDENT
                                                                              null,  --SSBSECT_PRNT_IND
                                                                              'Y',  --SSBSECT_GRADABLE_IND
                                                                               null,  --SSBSECT_TUIW_IND
                                                                               0, --SSBSECT_REG_ONEUP
                                                                               0, --SSBSECT_PRIOR_ENRL
                                                                               0, --SSBSECT_PROJ_ENRL
                                                                               50, --SSBSECT_MAX_ENRL
                                                                                0,--SSBSECT_ENRL
                                                                                50,--SSBSECT_SEATS_AVAIL
                                                                                null,--SSBSECT_TOT_CREDIT_HRS
                                                                                '0',--SSBSECT_CENSUS_ENRL
                                                                                TO_date(f_inicio, 'DD/MM/YYYY'),--SSBSECT_CENSUS_ENRL_DATE
                                                                                sysdate,--SSBSECT_ACTIVITY_DATE
                                                                                TO_date(f_inicio, 'DD/MM/YYYY'),--SSBSECT_PTRM_START_DATE
                                                                                TO_date(f_fin, 'DD/MM/YYYY'),--SSBSECT_PTRM_END_DATE
                                                                                sem,--SSBSECT_PTRM_WEEKS
                                                                                null,--SSBSECT_RESERVED_IND
                                                                                null, --SSBSECT_WAIT_CAPACITY
                                                                                null,--SSBSECT_WAIT_COUNT
                                                                                null,--SSBSECT_WAIT_AVAIL
                                                                                null,--SSBSECT_LEC_HR
                                                                                null,--SSBSECT_LAB_HR
                                                                                null,--SSBSECT_OTH_HR
                                                                                null,--SSBSECT_CONT_HR
                                                                                null,--SSBSECT_ACCT_CODE
                                                                                null,--SSBSECT_ACCL_CODE
                                                                                null,--SSBSECT_CENSUS_2_DATE
                                                                                null,--SSBSECT_ENRL_CUT_OFF_DATE
                                                                                null,--SSBSECT_ACAD_CUT_OFF_DATE
                                                                                null,--SSBSECT_DROP_CUT_OFF_DATE
                                                                                null,--SSBSECT_CENSUS_2_ENRL
                                                                                'Y',--SSBSECT_VOICE_AVAIL
                                                                                'N',--SSBSECT_CAPP_PREREQ_TEST_IND
                                                                                null,--SSBSECT_GSCH_NAME
                                                                                null,--SSBSECT_BEST_OF_COMP
                                                                                null,--SSBSECT_SUBSET_OF_COMP
                                                                                'NOP',--SSBSECT_INSM_CODE
                                                                                null,--SSBSECT_REG_FROM_DATE
                                                                                null,--SSBSECT_REG_TO_DATE
                                                                                null,--SSBSECT_LEARNER_REGSTART_FDATE
                                                                                null,--SSBSECT_LEARNER_REGSTART_TDATE
                                                                                null,--SSBSECT_DUNT_CODE
                                                                                null,--SSBSECT_NUMBER_OF_UNITS
                                                                                0,--SSBSECT_NUMBER_OF_EXTENSIONS
                                                                                'WWW_SIU',--SSBSECT_DATA_ORIGIN
                                                                                'WWW_SIU',--SSBSECT_USER_ID
                                                                                'MOOD',--SSBSECT_INTG_CDE
                                                                                'B',--SSBSECT_PREREQ_CHK_METHOD_CDE
                                                                                user,--SSBSECT_KEYWORD_INDEX_ID
                                                                                null,--SSBSECT_SCORE_OPEN_DATE
                                                                                null,--SSBSECT_SCORE_CUTOFF_DATE
                                                                                null,--SSBSECT_REAS_SCORE_OPEN_DATE
                                                                                null,--SSBSECT_REAS_SCORE_CTOF_DATE
                                                                                null,--SSBSECT_SURROGATE_ID
                                                                                null,--SSBSECT_VERSION
                                                                                PSEQ_NO);--SSBSECT_VPDI_CODE
                                    Exception
                                    When Others then

                                      vl_error := 'Se presento un Error al insertar el nuevo grupo ' ||sqlerrm;
                                      VSALIDA  := SQLERRM;
                                      --  INSERT INTO TWPASOW (VALOR1,VALOR2,VALOR3,VALOR4,VALOR5 )
                                      --  VALUES ('ERROR_INSRT_HORARIO_SSBSECT22  ',Ppidm, PSEQ_NO,VPparte, SUBSTR(VSALIDA,1,100));
                                  End;
                           -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 )
                           -- VALUES ('INSERTA_HORARIO_SSBSET2233 ',Ppidm, PSEQ_NO,Vsubj||'-'||Vcrse, sysdate, SUBSTR(VSALIDA,1,500));
                                                   Begin
                                                                update SOBTERM
                                                                     set SOBTERM_CRN_ONEUP = crn
                                                                where SOBTERM_TERM_CODE = Vperiodo;
                                                   Exception
                                                   When Others then
                                                     null;
                                                   End;

                               BEGIN
                                 select count(1)
                                     INTO cssrmet
                                    from  ssrmeet
                                  where SSRMEET_TERM_CODE = Vperiodo
                                  and SSRMEET_CRN = crn;

                                EXCEPTION WHEN OTHERS THEN
                                  VSALIDA  := SQLERRM;
                                  cssrmet := 0;
                                END;

                                            if cssrmet = 1 then
                                                null;
                                             else
                                                   Begin

                                                        insert into ssrmeet values(Vperiodo, crn, null,null,null,null,null,null, sysdate, TO_date(f_inicio, 'DD/MM/YYYY'), TO_date(f_fin, 'DD/MM/YYYY'), '01', null,null,null,null,null,null,null, 'ENL', null, credit, null, 0, null,null,null, 'CLVI', 'WWW_SIU', 'WWW_SIU', null,null,PSEQ_NO);
                                                    Exception
                                                    when Others then
                                                       VSALIDA  := 'Se presento un Error al insertar en ssrmeet ' ||sqlerrm;
                                                   End;
                                             end if;
                                        ---------AQUI BUSCAMOS EL PROFESOR DENTRO DE LA PARAMETRIZACION-------
                                                    begin

                                                        select ZSTPARA_PARAM_VALOR
                                                          INTO pidm_prof
                                                        from ZSTPARA
                                                        where ZSTPARA_MAPA_ID = 'DOCENTE_NIVELAC'
                                                        and  ZSTPARA_PARAM_DESC = VMATERIA;

                                                    Exception when others then
                                                      pidm_prof:=NULL;
                                                      VSALIDA  := 'EXITO';

                                                    End;

                                              if pidm_prof is null then
                                                   null; --NO HACE NADA--- PERO SIGUE EL FLUJO NO INSERTA EL PROFESOR  PARA CUANDO NO ESTA
                                                   -------CONFIGURADO EL PROFESOR EN EL PARAMETRIZADOR
                                              ELSE
                                                      ----dbms_output.put_line('Crea el CRN para el docente:'|| pidm_prof  ||'*'||crn);

                                                 --------------------convierte el id del profesor en su pidm----
                                                       select FGet_pidm(pidm_prof) into pidm_prof2  from dual;
                                                 ------------------------------------------------------------------

                                                      Begin
                                                            Select count (1)
                                                            Into vl_exite_prof
                                                            from sirasgn
                                                            Where SIRASGN_TERM_CODE = VPERIODO
                                                            And SIRASGN_CRN = crn
                                                            And SIRASGN_PIDM = pidm_prof2;
                                                       Exception
                                                        when others then
                                                          vl_exite_prof := 0;
                                                          VSALIDA  := 'Se presento un Error al consultal sirasgn ' ||sqlerrm;
                                                          -- insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6, valor7) values('ERRORRR_profe_mate11  ',ppidm, pidm_prof2,PPERIODO,crn,vl_exite_prof, sysdate );commit;
                                                       End;

                                                        -------------------------
                                                       If vl_exite_prof = 0 then
                                                                Begin
                                                                ----dbms_output.put_line('Salida inserta profe  20-B :'|| PPERIODO  ||'*'||crn||'*'|| pidm_prof||'*'||Vsubj||'*'||Vcrse||'*'||Vgrupo||'*'||schd||'*'||Pcampus);
                                                                --insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6) values('inserta_profe_mate22  ',ppidm , pidm_prof2,PPERIODO,crn, sysdate );commit;

                                                                select count(1)
                                                                  INTO csirasgn
                                                                from sirasgn
                                                                where SIRASGN_TERM_CODE = VPERIODO
                                                                and  SIRASGN_CRN       = crn
                                                                and  SIRASGN_PIDM      = pidm_prof2
                                                                and  SIRASGN_CATEGORY  = '01'
                                                                ;

                                                                if csirasgn > 0 then
                                                                null;
                                                                else
                                                                insert into sirasgn values(VPERIODO, crn, pidm_prof2, '01', 100, null, 100,'Y', null, null,
                                                                                            sysdate, null,null,null,null, 'WWW_SIU', 'WWW_SIU', null, null, null, null,  null,PSEQ_NO);

                                                                end if;
                                                                Exception
                                                                When Others then
                                                                 VSALIDA  := 'Se presento un Error al consultal sirasgn_count ' ||sqlerrm;
                                                                null;
                                                                End;
                                                       Else
                                                               Begin
                                                                    Update sirasgn
                                                                    set SIRASGN_PRIMARY_IND = null
                                                                     Where SIRASGN_TERM_CODE = VPERIODO
                                                                     And SIRASGN_CRN = crn;
                                                               Exception
                                                                When others then
                                                                 VSALIDA  := 'Se presento un Error al UPDATE sirasgn ' ||sqlerrm;
                                                                null;
                                                               End;

                                                                Begin
                                                                -----dbms_output.put_line('Salida INST EXEX  20-C :'|| PPERIODO  ||'*'||crn||'*'|| pidm_prof||'*'||Vsubj||'*'||Vcrse||'*'||VGrupo||'*'||schd||'*'||Pcampus);

                                                                --insert into twpasow(valor1,valor2,valor3,valor4, valor5, valor6) values('inserta_profe_mate33 ',ppidm, pidm_prof2,PPERIODO,crn, sysdate );commit;

                                                                        insert into sirasgn values(VPERIODO, crn, pidm_prof2, '01', 100, null, 100,'Y', null, null,
                                                                                                             sysdate, null,null,null,null, 'WWW_SIU', 'WWW_SIU', null, null, null, null,  null,PSEQ_NO);
                                                                Exception
                                                                When Others then
                                                                 VSALIDA  := 'Se presento un Error al INSERTAR sirasgn ' ||sqlerrm;
                                                                null;
                                                                End;

                                                       End if;
                                                end if;


                                                conta_ptrm :=0;
                                               ----dbms_output.put_line('salida 21  '||PPIDM ||'-'|| VPROGRAMA );
                                                    Begin
                                                         select count(*)
                                                            into conta_ptrm
                                                         from sfbetrm
                                                         where sfbetrm_term_code=VPERIODO
                                                         and     sfbetrm_pidm=PPIDM;
                                                    Exception
                                                        When Others then
                                                          conta_ptrm := 0;
                                                           VSALIDA  := 'Se presento un Error al conunt sfbetrm ' ||sqlerrm;
                                                    End;


                                                     if conta_ptrm =0 then
                                                            Begin
                                                                    insert into sfbetrm values(VPERIODO, PPIDM, 'EL', sysdate, 99.99, 'Y', null, sysdate, sysdate, null,null,null,null,'WWW_SIU', null,'WWW_SIU', null, 0,null,null, null,null,user,PSEQ_NO);
                                                            Exception
                                                            When Others then
                                                                VSALIDA  := ('Se presento un error al insertar en la tabla sfbetrm ' || sqlerrm);
                                                               --insert into twpasow(valor1,valor2,valor3,valor4, valor5) values('ERROR_inserta_sfbetrm22 ',pidm_prof2,PPERIODO,crn, sysdate );commit;
                                                            End;
                                                     end if;

                                             Begin
                                                     select distinct max(sorlcur_key_seqno)
                                                            into Vstudy
                                                      from sorlcur
                                                        where sorlcur_pidm        = PPIDM
                                                        and     sorlcur_program   = VPROGRAMA
                                                        and     sorlcur_lmod_code = 'LEARNER'
                                                      --  AND     SORLCUR_CACT_CODE = 'ACTIVE'
                                                        and     sorlcur_term_code = (select max(sorlcur_term_code) from sorlcur
                                                                                        where   sorlcur_pidm=PPIDM
                                                                                        and     sorlcur_program=VPROGRAMA
                                                                                        and     sorlcur_lmod_code='LEARNER'
                                                                                         --AND     SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                         )
                                                        ;
                                               Exception
                                               when Others then
                                                  Vstudy := 1;
                                                  VSALIDA  := 'Se presento un error al obtener la informacion de SORLCUR-key_seq_no ' ||PPIDM||'-'||  VPERIODO  ||'*'||crn|| sqlerrm;
                                               End;

                                        BEGIN

                                            SELECT COUNT(1)
                                            INTO VNSFRST
                                            FROM SFRSTCR  F
                                            WHERE  F.SFRSTCR_CRN     = crn
                                            AND F.SFRSTCR_TERM_CODE  =  VPERIODO
                                            AND F.SFRSTCR_PIDM       = PPIDM;

                                         EXCEPTION WHEN OTHERS THEN
                                         VNSFRST := 0;
                                          VSALIDA  := 'Se presento un Error al count sfrstrc  ' ||sqlerrm;
                                         END;
                               -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 , VALOR7, VALOR8 )
                                --VALUES ('PASOWW_SIU_INSERT_SFRSTCR_ANTES_vV2 ',Ppidm, VPERIODO,crn||'-'||VPparte,sysdate,  Vstudy , VNSFRST, VSALIDA);
                               -- COMMIT;
                                IF VNSFRST = 0  THEN
                                                   Begin
                                                  -- --dbms_output.put_line('Salida inserta sfrsctcr  21-D :'||PPIDM||'-'||  VPERIODO  ||'*'||crn||'*'|| Vgrupo||'*'||VPparte||'*'||credit_bill||'*'||credit||'*'||gmod||'*'||Vcampus);


                                                    insert into sfrstcr values(
                                                                                        VPERIODO,     --SFRSTCR_TERM_CODE
                                                                                        Ppidm,     --SFRSTCR_PIDM
                                                                                        crn,     --SFRSTCR_CRN
                                                                                        1,     --SFRSTCR_CLASS_SORT_KEY
                                                                                        Vgrupo,    --SFRSTCR_REG_SEQ
                                                                                        VPparte,    --SFRSTCR_PTRM_CODE
                                                                                        'RE',     --SFRSTCR_RSTS_CODE
                                                                                        sysdate,    --SFRSTCR_RSTS_DATE
                                                                                        null,    --SFRSTCR_ERROR_FLAG
                                                                                        null,    --SFRSTCR_MESSAGE
                                                                                        credit_bill,    --SFRSTCR_BILL_HR
                                                                                        3, --SFRSTCR_WAIV_HR
                                                                                        credit,     --SFRSTCR_CREDIT_HR
                                                                                        credit_bill,     --SFRSTCR_BILL_HR_HOLD
                                                                                        credit,     --SFRSTCR_CREDIT_HR_HOLD
                                                                                        gmod,     --SFRSTCR_GMOD_CODE
                                                                                        null,    --SFRSTCR_GRDE_CODE
                                                                                        null,    --SFRSTCR_GRDE_CODE_MID
                                                                                        null,    --SFRSTCR_GRDE_DATE
                                                                                        'N',    --SFRSTCR_DUPL_OVER
                                                                                        'N',    --SFRSTCR_LINK_OVER
                                                                                        'N',    --SFRSTCR_CORQ_OVER
                                                                                        'N',    --SFRSTCR_PREQ_OVER
                                                                                        'N',     --SFRSTCR_TIME_OVER
                                                                                        'N',     --SFRSTCR_CAPC_OVER
                                                                                        'N',     --SFRSTCR_LEVL_OVER
                                                                                        'N',     --SFRSTCR_COLL_OVER
                                                                                        'N',     --SFRSTCR_MAJR_OVER
                                                                                        'N',     --SFRSTCR_CLAS_OVER
                                                                                        'N',     --SFRSTCR_APPR_OVER
                                                                                        'N',     --SFRSTCR_APPR_RECEIVED_IND
                                                                                        sysdate,      --SFRSTCR_ADD_DATE
                                                                                        sysdate,     --SFRSTCR_ACTIVITY_DATE
                                                                                        Vnivel,     --SFRSTCR_LEVL_CODE
                                                                                        vcampus,     --SFRSTCR_CAMP_CODE
                                                                                        vmateria,     --SFRSTCR_RESERVED_KEY
                                                                                        null,     --SFRSTCR_ATTEND_HR
                                                                                        'Y',     --SFRSTCR_REPT_OVER
                                                                                        'N' ,    --SFRSTCR_RPTH_OVER
                                                                                        null,    --SFRSTCR_TEST_OVER
                                                                                        'N',    --SFRSTCR_CAMP_OVER
                                                                                        'WWW_SIU',    --SFRSTCR_USER
                                                                                        'N',    --SFRSTCR_DEGC_OVER
                                                                                        'N',    --SFRSTCR_PROG_OVER
                                                                                        null,    --SFRSTCR_LAST_ATTEND
                                                                                        null,    --SFRSTCR_GCMT_CODE
                                                                                        'WWW_SIU',    --SFRSTCR_DATA_ORIGIN
                                                                                        sysdate,   --SFRSTCR_ASSESS_ACTIVITY_DATE
                                                                                        'N',  --SFRSTCR_DEPT_OVER
                                                                                        'N',  --SFRSTCR_ATTS_OVER
                                                                                        'N', --SFRSTCR_CHRT_OVER
                                                                                        null, --SFRSTCR_RMSG_CDE
                                                                                        null,  --SFRSTCR_WL_PRIORITY
                                                                                        null,  --SFRSTCR_WL_PRIORITY_ORIG
                                                                                        null,  --SFRSTCR_GRDE_CODE_INCMP_FINAL
                                                                                        null, --SFRSTCR_INCOMPLETE_EXT_DATE
                                                                                        'N', --SFRSTCR_MEXC_OVER
                                                                                        Vstudy,--SFRSTCR_STSP_KEY_SEQUENCE
                                                                                        null,--SFRSTCR_BRDH_SEQ_NUM
                                                                                        '01',--SFRSTCR_BLCK_CODE
                                                                                        null,--SFRSTCR_STRH_SEQNO
                                                                                        PSEQ_NO, --SFRSTCR_STRD_SEQNO
                                                                                        null,  --SFRSTCR_SURROGATE_ID
                                                                                        null, --SFRSTCR_VERSION
                                                                                        'WWW_SIU',--SFRSTCR_USER_ID
                                                                                        null );--SFRSTCR_VPDI_CODE

                                                         ----dbms_output.put_line('DESPUES de insert stfrscr ' || PPIDM||'-'||PPERIODO||'-'|| crn|| Vgrupo||'-'||  VPparte||'NIVE'  );
                                                        -- vl_error  :=  'SI INSERTA SFRSTCR OK ';
                                                       -- INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 )
                                                        --VALUES ('INSRT_SFRSTCR_SEGUNDO22 ',Ppidm, PSEQ_NO,Vperiodo,sysdate, SUBSTR(vl_error,1,500));

                                                                Begin
                                                                     update ssbsect
                                                                            set ssbsect_enrl = ssbsect_enrl + 1
                                                                      where SSBSECT_TERM_CODE = VPERIODO
                                                                      And SSBSECT_CRN  = crn;
                                                                Exception
                                                                When Others then
                                                                VSALIDA  := 'Se presento un error al actualizar el enrolamiento ' ||sqlerrm;
                                                                End;

                                                                Begin
                                                                        update ssbsect
                                                                            set ssbsect_seats_avail=ssbsect_seats_avail -1
                                                                        where SSBSECT_TERM_CODE = VPERIODO
                                                                         And SSBSECT_CRN  = crn;
                                                                Exception
                                                                When Others then
                                                                    VSALIDA  := 'Se presento un error al actualizar la disponibilidad del grupo ' ||sqlerrm;
                                                                End;

                                                                Begin
                                                                         update ssbsect
                                                                                set ssbsect_census_enrl=ssbsect_enrl
                                                                         Where SSBSECT_TERM_CODE = VPERIODO
                                                                         And SSBSECT_CRN  = crn;
                                                                Exception
                                                                When Others then
                                                                    VSALIDA  := 'Se presento un error al actualizar el Censo del grupo ' ||sqlerrm;
                                                                End;

                                                                Begin
                                                                    Update sgbstdn a
                                                                    set a.SGBSTDN_STYP_CODE ='C',
                                                                        A.SGBSTDN_USER_ID  = 'WWW_SIU'
                                                                    Where a.SGBSTDN_PIDM = Ppidm
                                                                    And a.SGBSTDN_TERM_CODE_EFF = (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                                                                           from sgbstdn a1
                                                                                                                           Where a1.SGBSTDN_PIDM = a.SGBSTDN_PIDM
                                                                                                                           And a1.SGBSTDN_PROGRAM_1 = a.SGBSTDN_PROGRAM_1)
                                                                     And a.SGBSTDN_PROGRAM_1 = VPROGRAMA;
                                                                Exception
                                                                    When Others then
                                                                    VSALIDA  := 'Se presento un error al actualizar el tipo de alumno en sgbstdn ' ||sqlerrm;
                                                                End;



                                                                conta_ptrm:=0;

                                                                Begin
                                                                    Select count (*)
                                                                        Into conta_ptrm
                                                                    from sfrareg
                                                                    where SFRAREG_PIDM = Ppidm
                                                                    And SFRAREG_TERM_CODE = VPERIODO
                                                                    And SFRAREG_CRN = crn
                                                                    And SFRAREG_EXTENSION_NUMBER = 0
                                                                    And SFRAREG_RSTS_CODE = 'RE';
                                                                Exception
                                                                When Others then
                                                                   conta_ptrm :=0;
                                                                    VSALIDA  := 'Se presento un Error al count sfrareg ' ||sqlerrm;
                                                                End;

                                                                If conta_ptrm = 0 then

                                                                     Begin
                                                                       ----dbms_output.put_line(' SALIDA 22A--antes de insertar sfrareg  ' || Ppidm||'-'||PPERIODO||'-'|| crn||f_inicio||'-'|| f_fin||'-'|| 'N'||'-'||'N'   );
                                                                        if  f_inicio is not null  then
                                                                             insert into sfrareg values(PPIDM, VPERIODO, crn , 0, 'RE', TO_date(f_inicio, 'DD/MM/YYYY'), TO_date(f_fin, 'DD/MM/YYYY'), 'N','N', sysdate, 'WWW_SIU', null,null,null,null,null,null,null,null, 'WWW_SIU', sysdate, null,null,PSEQ_NO);
                                                                        end if;

                                                                     Exception
                                                                       When Others then
                                                                          VSALIDA  := 'error al insertar el registro de la materia para sfrareg  ' ||sqlerrm;
                                                                     End;
                                                                End if;
                                                      -- commit;
                                                    Exception
                                                   when Others then
                                                    --INSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4, valor6 )
                                                     --VALUES ('PASOWWW_SIU_GRal',Ppidm, PSEQ_NO,sysdate,  SUBSTR(vl_error,1,100));
                                                       VSALIDA  := 'Se presento un error al insertar al alumno en el grupo3  ' ||sqlerrm;
                                                End;
                                  END IF;
                                    -- commit;
                                                  ----dbms_output.put_line('se termina proceso gral ' ||VSALIDA);
     else
        VSALIDA  := 'No inserto Horario: ' ||sqlerrm;

                        End if;
   END IF; -----ES EL FIN FINAL DE LA COMPACTACION DE GRUPO


    IF VSALIDA = 'EXITO' then
    null;


     ---------------------------aqui va el update con el numero de recibo nuevo glovicx 26/11/2019

       begin  -------------AQUI BUSCA EL NUMERO DE ORDEN ACTUAL EL MAS RECIENTE
        select MAX(TBRACCD_RECEIPT_NUMBER)
        into vno_orden
            from tbraccd t
            where tbraccd_pidm =  ppidm
          -- and TBRACCD_DESC like ('%NIVELA%')
           -- and t.TBRACCD_DOCUMENT_NUMBER = vmateria
           -- and t.TBRACCD_USER       =  'WWW_SIU'
           AND TBRACCD_CROSSREF_NUMBER = PSEQ_NO
           ;
     exception when others then

     vno_orden := 0;
     end;

         BEGIN
                       -------BUSCA SI EL CRN YA EXISTIA Y TENIA UN NUMERO DE ORDEN POR LA COMPACTACION DE GRUPO
                       ------- SI YA EXISTE ENTONCES TENGO QUE RECUPERAR ESA ORDEN Y ACTUALIZARLA EN LA CARTERA CANCELADA
                       -----  ESTA REGLA SE ACORDO CON VICTOR RAMIREZ 04/12/2019-----
            SELECT SFRSTCR_VPDI_CODE
            INTO NO_ORDEN_OLD
            FROM SFRSTCR
            where 1= 1
            and SFRSTCR_PIDM = ppidm
            and SFRSTCR_CRN  = CRN
            And substr (SFRSTCR_TERM_CODE, 5,1) = '8'
            And SFRSTCR_RSTS_CODE = 'RE'
            ;

         EXCEPTION WHEN OTHERS THEN
           NO_ORDEN_OLD := 0;
         END;

       IF NO_ORDEN_OLD > 0 THEN-----SI HAY NUMERO DE ORDEN VIEJO LO ACTUALIZA EN LA CARTERA VIEJA POR EL NUEVO NUM ORDEN

          UPDATE  tbraccd t
            SET TBRACCD_RECEIPT_NUMBER = vno_orden --NO_ORDEN_NUEVO
            where tbraccd_pidm =  ppidm
          --  and TBRACCD_DESC like ('%NIVELA%')
            --and t.TBRACCD_DOCUMENT_NUMBER like (:vmateria
            AND TBRACCD_RECEIPT_NUMBER = NO_ORDEN_OLD  --NO_ORden anterior
            ;
       END IF;

     if vno_orden > 0 then
       ----dbms_output.put_line('salida no_orden '||vno_orden );
       begin

          update  SFRSTCR
             set SFRSTCR_VPDI_CODE  = vno_orden,
               SFRSTCR_ADD_DATE     = sysdate
              where 1= 1
               and SFRSTCR_PIDM = ppidm
               and SFRSTCR_CRN  = CRN
               And substr (SFRSTCR_TERM_CODE, 5,1) = '8'
               And SFRSTCR_RSTS_CODE = 'RE';

        --  --dbms_output.put_line('Actualiza::  '||vno_orden||'-'|| jump.pidm ||'--'||jump.CRN ||'--'||jump.materia );
       exception when others then
       null;
        ----dbms_output.put_line('error en UPDATE :  ' ||sqlerrm  );
        end;


     end if;

     ---------------------------------------------------------------------------------fin

     COMMIT;
     ----dbms_output.put_line('se termina proceso gral--1 ' ||pregreso);
    else
    vsalida := sqlerrm;
     ----dbms_output.put_line('se termina proceso gral--3 ' ||VSALIDA);

    -- rollback;

  -- iNSERT INTO TWPASOW ( VALOR1, VALOR2,VALOR3,VALOR4,VALOR5, valor6 )
  --  VALUES ('PASOWW_SIU_FINALIZA_HORARIO_ERROR ',Ppidm, PSEQ_NO,--sysdate,  NULL,SUBSTR(VSALIDA,1,90));
    -- COMMIT;
    end if;
-- INSERT INTO TWPASO VALUES ('PASOWWW_SIU_FIN',Ppidm, PSEQ_NO, vl_error);
 COMMIT;

  RETURN ( VSALIDA);

--commit;
END IF;
exception when others then
     -----dbms_output.put_line('ERRORR:  termina proceso gral ' ||VSALIDA);
   --pregreso := VSALIDA;
  --- rollback;
  NULL;
-- raise_application_error (-20002,'ERROR EN CARGA HORARIO '||vl_error||'-++'|| sqlerrm);
end f_inserta_horario_nivg;



FUNCTION F_REJE_QR (PPIDM NUMBER, pprogram varchar2, PCODE  VARCHAR2 ) Return VARCHAR2  IS

--  esta función tiene como objetivo validar si tiene o no el beneficio de adquirir el reconocimiento de las sesiones ejecutivas
--  en el modulo de QR.    proyecto   glovicx 13.10.022

VDTLLE    VARCHAR2(6);
vestatus  VARCHAR2(6);
vcampus   VARCHAR2(6);
vnivel    VARCHAR2(6);
vsp       VARCHAR2(2);
VSALIDA   VARCHAR2(200):='EXITO';
VEJECUTIVO  VARCHAR2(1):='N';
VEJECUTIVE  VARCHAR2(15):= 'EJECUT';
VAVANCE     VARCHAR2(1):= 'N';
VADEUDO     NUMBER := 0;

/*Sí dentro de su paquete se encuentran las sesiones ejecutivas incluídas, es del Campus
 Mex 01 / Ecu 29 / Col 20 / Per 24 / Bol 33, tiene estatus egresado,
 no tiene adeudo y lleva un avance extracurricular del 80% en adelante
*/


BEGIN

---- validaciones necesarias
     begin
            select DISTINCT estatus, campus, nivel, sp
             INTO  vestatus, vcampus, vnivel, vsp
            from tztprog
            where 1=1
            and pidm = ppidm
            and programa = pprogram;

     exception when others then

       vestatus := '';
       vcampus := '';
       vnivel := '';
       vsp    := '';

     end;

    ----dbms_output.PUT_LINE(' DESPUES DE TZTPROG  '||vestatus||'-'|| VCAMPUS||'-'||VNIVEL||'-'||VSP   );


--  PRIMERO SE VALIDA  si adquirio x pkt de venta el beneficio de seción ejecutiva mediante el agrupador
    BEGIN


        select distinct 'Y'
         INTO VDTLLE
        from tbraccd t
        where 1=1
        and t.tbraccd_pidm = ppidm
        and t.TBRACCD_STSP_KEY_SEQUENCE = Vsp
        and T.TBRACCD_DETAIL_CODE in (SELECT DISTINCT ZSTPARA_PARAM_VALOR
                                        from ZSTPARA
                                        where 1=1
                                        AND ZSTPARA_MAPA_ID = 'COD_DET_CERO'
                                        AND ZSTPARA_PARAM_ID = Vcampus);


     exception when others then

      VDTLLE   := 'N';
      VSALIDA  := 'NO TIENE EL  BENEFICIO';
    END;

   ----dbms_output.PUT_LINE(' DESPUES DE VAL 1  '||vestatus||'-'|| VCAMPUS||'-'||VNIVEL||'-'||VSP ||'-'|| VDTLLE  );
-- PARA CUALQUIER CASO HAY QUE BUSCAR EL 5 DE AVANCE EN LA NUEVA TABLA SZTHITE

  BEGIN
      SELECT DISTINCT 'Y'
         INTO VAVANCE
            FROM SZTHITE
            WHERE 1=1
            AND SZTHITE_PIDM =  ppidm
            AND SZTHITE_PROG = PPROGRAM
            and SZTHITE_ALIANZA = 'EJEC'
            AND SZTHITE_AVANCE >= (SELECT  DISTINCT ZSTPARA_PARAM_VALOR
                                            from ZSTPARA
                                            where 1=1
                                            AND ZSTPARA_PARAM_ID = PCODE
                                            AND ZSTPARA_MAPA_ID = 'EXTRA_EJECUTIVA') ;

   exception when others then

      VAVANCE   :='N' ;
      VSALIDA  := 'NO TIENE EL AVANCE';

   END;

----dbms_output.PUT_LINE(' DESPUES DE AVANCE  '||vestatus||'-'|| VCAMPUS||'-'||VNIVEL||'-'||VSP ||'-'|| VAVANCE  );
--- BUSCAMOS SI TIENE ADEUDO EN LA CARTERA


 VADEUDO :=  NVL(BANINST1.PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia_Titulo (ppidm),0);

 ----dbms_output.PUT_LINE(' DESPUES DE ADEUDO  '||vestatus||'-'|| VCAMPUS||'-'||VNIVEL||'-'||VSP ||'-'|| VADEUDO  );

-- SEGUNDA VALIDACIÓN PARA SABER SI PUEDE ADQUIRIR EL RECONOCIMIENTO MEDIANTE EL PROGRAMA DE SESION EJECUTIVA

   BEGIN

            SELECT DISTINCT 'Y'
            INTO VEJECUTIVO
            FROM sztdtec
            WHERE 1=1
            AND SZTDTEC_CAMP_CODE = VCAMPUS
            AND SZTDTEC_MOD_TYPE  = 'S'
            AND SZTDTEC_PROGRAM   = PPROGRAM
            --AND upper(SZTDTEC_PROGRAMA_COMP) LIKE '%'||UPPER(VEJECUTIVE)||'%'
            ;

     exception when others then

      VEJECUTIVO   := 'N';
      VSALIDA  := 'NO TIENE EL  BENEFICIO';

   END;

----dbms_output.PUT_LINE(' DESPUES DE PROGRAMA EJECUTIVO  '||vestatus||'-'|| VCAMPUS||'-'||VNIVEL||'-'||VSP ||'-'|| VEJECUTIVO  );

---  SI EL AVAVNCE ES MAYOR AL 80% ESTATUS = EG Y NO TIENE ADEUDO  ENTONCES SI TIENE EL BENEFICIO Y ES EXITO

IF vestatus != 'XX' AND VADEUDO <= 0 AND VAVANCE = 'Y' AND VDTLLE = 'Y' THEN -- SI CUMPLE TODAS ESTAS VALIDACIONES ES EXITO

----dbms_output.PUT_LINE(' DENTRO EJECUTIVO  '||vestatus||'-'|| VADEUDO|--|'-'||VAVANCE||'-'||VDTLLE ||'-'|| VEJECUTIVO  );
VSALIDA  := 'EXITO';

ELSIF VEJECUTIVO = 'Y' AND vestatus != 'Xx' AND VADEUDO <= 0 AND VAVANCE = 'Y'  THEN -- SI CUMPLE TODAS ESTAS VALIDACIONES ES EXITO

----dbms_output.PUT_LINE(' DENTRO EJECUTIVO XX2  '||vestatus||'-'|| VADEUDO||'-'||VAVANCE||'-'||VDTLLE ||'-'|| VEJECUTIVO  );
VSALIDA  := 'EXITO';

ELSE

----dbms_output.PUT_LINE(' DENTRO EJECUTIVO XX3  '||vestatus||'-'|| ----VADEUDO||'-'||VAVANCE||'-'||VDTLLE ||'-'|| VEJECUTIVO  );
vSALIDA  := 'NO TIENE EL  BENEFICIO';

END IF;


----dbms_output.PUT_LINE(' DESPUES FINAL   '||VSALIDA  );

RETURN VSALIDA ;

EXCEPTION WHEN OTHERS THEN

VSALIDA := SQLERRM;

----dbms_output.PUT_LINE(' ERROR EN FINAL GRAL    '||VSALIDA  );

end F_REJE_QR;

FUNCTION F_COFU_ESTADO (PPIDM NUMBER, PSEQNO varchar2, PCODE  VARCHAR2 ) Return VARCHAR2  IS

VSALIDA    VARCHAR2(600):= 'EXITO';
Vpago   VARCHAR2(600);

BEGIN
  -- ajuste que pidio fer por que se cambio la posición de dato de numero de pagos COFU, glovicx 28,05,2024

      select  substr(SVRSVAD_ADDL_DATA_DESC,instr(SVRSVAD_ADDL_DATA_DESC,'|',1)+2,2 )  pago
        INTO Vpago
      from svrsvpr v,SVRSVAD VA
        where 1=1
            ANd SVRSVPR_SRVC_CODE = PCODE
            AND  SVRSVPR_PROTOCOL_SEQ_NO = PSEQNO
            anD  SVRSVPR_PIDM    =  PPIDM
            AND SVRSVPR_SRVS_CODE != 'CA'
           and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO
         and va.SVRSVAD_ADDL_DATA_SEQ = '5'
        order by 1 desc
        ;

RETURN (Vpago);

EXCEPTION WHEN OTHERS THEN

VSALIDA := SQLERRM;

RETURN VSALIDA;
null;
----dbms_output.PUT_LINE(' ERROR EN F_COFU_ESTADO  GRAL    '||VSALIDA  );

END F_COFU_ESTADO;

FUNCTION F_LIMITA_CERTIFICACIONES ( P_PIDM NUMBER, P_CODE VARCHAR2 ) RETURN VARCHAR2 IS

vvalida varchar2(1):='N';
vtipo   varchar2(20);
Vrevisa   varchar2(20);
vconta  number:=0;
vconta2  number:=0;
vsalida  varchar2(50):='EXITO';

BEGIN
--  Esta funcion sirve para limitar las compras de los certificados segun la configuración 
--  de la tabla sztccss, valida el codigo que escogio para ver cuantas certificaciones o experiencias,plataformas, o idiomas puede comprar.
-- glovicx 21.06.2023

-- primero validamos el para ACC_SINRESTRICC  ahi estan las certificaciones que NO tienen restricciones

   begin
                  
            select 'Y'
            into vvalida
            from ZSTPARA
            where 1=1 
            and ZSTPARA_MAPA_ID = 'ACC_SINRESTRICC' 
            and ZSTPARA_PARAM_ID = P_CODE  ;
   
   exception when others then
      vvalida := 'N';
     
   end;
   ---  aqui validamos el codigo que se va comprar que tipo es;
     begin
        select distinct  g.SZT_TIPO_ALIANZA
           INTO vtipo
        from sztgece g
          where 1=1
            and G.SZT_CODE_SERV = p_code;
     
      exception when others then
      vtipo := 'N';
     
   end;
     
     
   
 IF vvalida = 'Y' then -- aqui deja pasar sin restricciones
 null;
 
 else
  ---  se limpian las variables
  vconta2 := 0;
  vconta := 0;
 
 
 ---- aqui se generan las limitaciones que estab en la tabla sztccss x accesorio 
   for jump in (select distinct 
                   SZT_CERTIFICACIONES as certificacion,
                   SZT_PLATAFORMAS as plataformas,
                   SZT_IDIOMAS  as idioma,
                   SZT_EXPERIENCIAS as experiencias,
                   SZT_ACCESORIO_1 as acc1,
                   SZT_ACCESORIO_2 as acc2,
                   SZT_ACCESORIO_3 as acc3
                    from SZtCCSS
                        where 1=1
                        and SZT_ACCESORIO = P_CODE )  loop
    
         
         CASE  when UPPER(vtipo) =  'CERTIFICACION' THEN -- para sacar el num de cuantos puedo comprar x categoria
         vconta := jump.certificacion; 
         
           when UPPER(vtipo) =  'PLATAFORMAS' THEN
         vconta := jump.plataformas;
         
          when UPPER(vtipo) =  'IDIOMA' THEN
         vconta := jump.idioma;
         
         when UPPER(vtipo) =  'EXPERIENCIAS' THEN
         vconta := jump.experiencias;
         
         ELSE
         vconta := 0;
         END CASE ;
   
    -----  AQUI BUSCAMOS  si ya compro con anterioridad algun tipo de accesorio 
    
         begin
                 
                 select distinct NVL(COUNT(1),0)
                  into vconta2
                 from goradid
                    where 1=1
                    and GORADID_PIDM = p_pidm
                    and GORADID_ADID_CODE in (select  distinct G.SZT_ETIQUETA
                                                                            from saturn.SZtGECE g
                                                                            where 1=1
                                                                            and UPPER(g.SZT_TIPO_ALIANZA) LIKE  UPPER(vtipo)||'%' );

         exception when others then
          vconta2 := 0;
         
         end;
    ---si el número de acc comprados(vconta2) es mayor que el permitido(vconta) entonces regresa mensaje no se puede comprar
   
     IF VCONTA2 <  VCONTA THEN 
        VSALIDA := 'EXITO';
        
        ELSE
         VSALIDA := 'Ya cuentas con el limite permitido';
        
     END IF;
   
   
   end loop;
 
 
 null;
 
 end if; 


return (vsalida);


END F_LIMITA_CERTIFICACIONES;


FUNCTION  F_NIVE_CERO (PPIDM NUMBER, PCODE VARCHAR2, PPROGRAMA VARCHAR2, PMATERIA VARCHAR2  )  RETURN VARCHAR2
IS

/*
ESTA FUNCION  tiene la funcionalidad para determinar si el alumno tiene nivelaciones en costo cero o no 
created  by glovicx 
date     08/09/2023
*/

Vmatriculado   varchar2(1):= 'N' ;
vsalida        VARCHAR2(1000):='EXITO';
vsaldo         NUMBER:=0;
vadeudo        varchar2(1):= 'N' ;
VCAMPUS        varchar2(4);    
VNIVEL         varchar2(4);
VAVCU          varchar2(8);
vcuenta_mate   number:=0;
vcuenta_mate2  number:=0;
vmax_mate      varchar2(1):='N';
vavcumat         varchar2(1):='N';
V2BIM_NIVE     number:=0;
VNP            varchar2(1):='N';
v2damatecero   number:=0;
vseqno         number:=0;
vmateria2     varchar2(20);
Vestatus      varchar2(2);
vacreditaMA   VARCHAR2(100);
vacreditaLI   VARCHAR2(100);
VACREDITA    VARCHAR2(100);
VTERMCODE    varchar2(8):='000000';

BEGIN
------seteamos variable    
vcuenta_mate   :=0;
vcuenta_mate2  :=0;
vmax_mate      :='N';
vavcumat         :='N';
V2BIM_NIVE     :=0;
VNP            :='N';

            ----- VALIDAMOS cuantas materias tiene en CERO en general debe tener menos de 5 nives gratis
            begin
                select  NVL(COUNT(1),0) CUENTA  
                   INTO vcuenta_mate 
                     from SVRSVPR  v
                        WHERE 1=1
                          and  v.SVRSVPR_PIDM = PPIDM
                          ANd  V.SVRSVPR_SRVC_CODE  = PCODE
                          and  v.SVRSVPR_SRVS_CODE  NOT IN  ('CA')
                          AND V.SVRSVPR_STEP_COMMENT = 'NIVE_CERO'
                          and  v.SVRSVPR_PROTOCOL_AMOUNT = 0
                    ORDER BY SVRSVPR_PROTOCOL_SEQ_NO DESC;

             EXCEPTION WHEN OTHERS THEN
               vcuenta_mate := 0;
                vsalida    := 'ERROR ya cumplio con el limite de materias costo cero';
               -- DBMS_output.PUT_LINE(VSALIDA );
             end;
 
---- primer regla antes de todas explicada x alexis y fer en junta 10.11.2023
-- no impoortando si ya tiene o no beneficio costo cero si la materia TIENE un NP en su calificación entonces SE LE COBRA
        begin
            
        select distinct  'Y'
           INTO  VNP
           from sfrstcr f, ssbsect bb
           where 1=1
        and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
        and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
        and f.SFRSTCR_PIDM = ppidm
        and F.SFRSTCR_RSTS_CODE  = 'RE'
        and F.SFRSTCR_GRDE_CODE  = 'NP'
        and BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB  in (pmateria)
        and BB.SSBSECT_SURROGATE_ID  = (select max (B2.SSBSECT_SURROGATE_ID)
                                           from  sfrstcr f2, ssbsect b2
                                            where 1=1
                                            and F2.SFRSTCR_CRN  = B2.SSBSECT_CRN
                                            and F2.SFRSTCR_TERM_CODE  = B2.SSBSECT_TERM_CODE
                                            and f2.SFRSTCR_PIDM = ppidm
                                            and F2.SFRSTCR_RSTS_CODE  = 'RE'
                                             and B2.SSBSECT_SUBJ_CODE||B2.SSBSECT_CRSE_NUMB =pmateria);

            
       exception when others then
         VNP  := 'N';
       
       end;
       
       -- dbms_output.put_line('primer validacion NP  '|| VNP||' cuenta_mate ' ||vcuenta_mate  );
        -- 1RA REGLA ESTUDIANTES MATRICULADOS 
         begin
                           
            select 'Y', SGBSTDN_LEVL_CODE, SGBSTDN_CAMP_CODE --,SGBSTDN_TERM_CODE_CTLG_1
                into Vmatriculado, vnivel, vcampus   --,VTERMCODE
              from sgbstdn d
               where 1=1
                and  d.SGBSTDN_PIDM = ppidm
                and  d.SGBSTDN_PROGRAM_1  = PPROGRAMA
                and  d.SGBSTDN_STST_CODE = 'MA' 
                and  d.SGBSTDN_SURROGATE_ID  = (select max(d2.SGBSTDN_SURROGATE_ID) from sgbstdn d2
                                    where 1=1 
                                     and d2.SGBSTDN_PIDM =  d.SGBSTDN_PIDM
                                     and d2.SGBSTDN_PROGRAM_1 = d.SGBSTDN_PROGRAM_1 
                                    -- and d2.SGBSTDN_STST_CODE = 'MA'  esta opcion no va para que tome todos los estatus
                                     );
         
         
         exception when others then
              Vmatriculado := 'N' ;
              vnivel       := '' ;
              vcampus   := '' ;
              vsalida    := 'ERROR no encontro MATRICULADO';
              --DBMS_output.PUT_LINE(VSALIDA );
         end;
   
   IF vnivel = 'LI' then
     vacredita :=  vacreditaLI; 
   else
     vacredita :=  vacreditaMA;
   end if;
         -- dbms_output.put_line('salida de NPs  '||   VNP);
 IF VNP = 'N' THEN  ---- si puede comprar con beneficio costo cero
   NULL;
          
         IF   vcuenta_mate = 0 THEN -- QUIERE DECIR QUE NO TIENE Y ES LA PRIMERA NO HACE LA VALIDACION DE ULTIMA MATERIA APROBADA COSTO CERO
                
                vmax_mate := 'Y';
                vcuenta_mate2 := 1;  --- por que no tiene nungana nivelacion
                
         ELSIF  vcuenta_mate > 0  and  vcuenta_mate <= 5 THEN -- AQUI SE PODRIA PONER EN UN PARA;  EL MISMO QUE SE UTILIZA PARA PRENDER Y APAGAR  
               NULL;
          
          --1ro hacer un query para optener la ultima materia costo cero estatus CL sacar seqno
            begin
                    --1ro
              
              select max(SVRSVPR_PROTOCOL_SEQ_NO),SVRSVAD_ADDL_DATA_CDE
               INTO  vseqno, vmateria2
                from svrsvpr v,SVRSVAD VA
                where 1=1
                ANd SVRSVPR_SRVC_CODE = pcode
                anD  SVRSVPR_PIDM    = ppidm
                and v.SVRSVPR_SRVS_CODE  NOT IN  ('CA')
                AND V.SVRSVPR_STEP_COMMENT = 'NIVE_CERO'
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO 
                 and va.SVRSVAD_ADDL_DATA_SEQ = '2'
                group by SVRSVAD_ADDL_DATA_CDE;
                
            exception when others then
              vseqno  := null;
              vmateria2  := null;
            end; 
              -- DBMS_OUTPUT.PUT_LINE('SALIDA SEQNO, MATERIA  '||  VSEQNO||'-'|| VMATERIA2);
               
              ---2do-----si da estatus PA quiere decir que existe otra nive de la misma materia CON costo y que se hizo despues de la del cosot cero
             begin   
               select SVRSVPR_SRVS_CODE as cuenta               
                INTO Vestatus
                 from svrsvpr v,SVRSVAD VA
                   where 1=1
                    ANd SVRSVPR_SRVC_CODE = pcode
                    anD  SVRSVPR_PIDM   = ppidm
                    and v.SVRSVPR_SRVS_CODE  NOT IN  ('CA')
                    and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO 
                     and va.SVRSVAD_ADDL_DATA_SEQ = '2'
                     and SVRSVAD_ADDL_DATA_CDE = vmateria2
                     and  V.SVRSVPR_PROTOCOL_SEQ_NO > vseqno ;   
                     
              exception when others then
              Vestatus := null;
              
              end;
           -- DBMS_OUTPUT.PUT_LINE('SALIDA ESTATUS  '||  Vestatus);
         
          ---4ta regla valida que la materia que viene en el parametro no la haya pedido antes y no este reprobada
          --          
                   begin
                          
                     select 'N'--- NO quiere decir que no va costo cero, x que ya la pidio y la reproboLA MISMA MATERIA
                      INTO vmax_mate
                       from sfrstcr f, svrsvpr v,SVRSVAD VA
                         where 1=1
                            and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO 
                            and v.SVRSVPR_PIDM = f.SFRSTCR_PIDM
                            and V.SVRSVPR_PROTOCOL_SEQ_NO = f.SFRSTCR_STRD_SEQNO
                            and f.SFRSTCR_PIDM = ppidm
                            and v.SVRSVPR_SRVC_CODE  = pcode
                            and f.SFRSTCR_RESERVED_KEY  = pmateria
                            and va.SVRSVAD_ADDL_DATA_SEQ = '2'
                            and v.SVRSVPR_SRVS_CODE  NOT IN  ('CA')
                            AND V.SVRSVPR_STEP_COMMENT = 'NIVE_CERO'
                            and F.SFRSTCR_RSTS_CODE  = 'RE'
                            and substr(F.SFRSTCR_TERM_CODE,5,1)  = '8'
                            and F.SFRSTCR_GRDE_CODE   in ('NP','NA','5.0');

                                                 
                     
                     
                   exception when others then
                     vmax_mate := 'Y';
                     --vsalida    := ' esa materia NO la a pedido en costo cero';
                    -- DBMS_output.PUT_LINE('error en ya pidio la materia '||vmax_mate );
                      
                   end;
                   
           IF Vestatus = 'PA' then
          ---3ro-si es pagado entonces se puede comprara otra nive cero podria solo setear la variable vcuenta_mate2 =1
           vcuenta_mate2 :=1;
          --  DBMS_OUTPUT.PUT_LINE('SALIDA ESTATUSXX2  '||  vcuenta_mate2);
           
          ELSE
          
           IF vnivel = 'LI' then      
                  ----- 3RA REGLA SE valida que CUALQUIER MATERIA COSTO CERO, que haya pedido tenga calf de aprobatoria para tener nuevamente
              ----- el beneficio de la segunda materia (cualquiera) x peeriodo
             begin
                    select distinct NVL(count(SVRSVPR_PIDM),0)--- SI regresa "1" quiere decir que la ultima materia de costo cero si esta a probada
                      INTO vcuenta_mate2               -- entonces si puede pedir la segunda en costo cero
                       from sfrstcr f, svrsvpr v,SVRSVAD VA,shrgrde SH
                         where 1=1
                            and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO 
                            and v.SVRSVPR_PIDM = f.SFRSTCR_PIDM
                            and V.SVRSVPR_PROTOCOL_SEQ_NO = f.SFRSTCR_STRD_SEQNO
                            and f.SFRSTCR_PIDM = ppidm
                            and v.SVRSVPR_SRVC_CODE  = pcode
                           -- and f.SFRSTCR_RESERVED_KEY  = pmateria
                            and va.SVRSVAD_ADDL_DATA_SEQ = '2'
                            and v.SVRSVPR_SRVS_CODE  NOT IN  ('CA')
                            AND V.SVRSVPR_STEP_COMMENT = 'NIVE_CERO'
                            and F.SFRSTCR_RSTS_CODE  = 'RE'
                            and substr(F.SFRSTCR_TERM_CODE,5,1)  = '8'
                            and F.SFRSTCR_GRDE_CODE  IN ('6.0','7.0','8.0','9.0','10.0') -- valida que la materia anterior sea aprobatoria
                            AND f.SFRSTCR_GRDE_CODE = SH.SHRGRDE_CODE
                            AND f.SFRSTCR_LEVL_CODE = SH.SHRGRDE_LEVL_CODE
                            AND SH.SHRGRDE_TERM_CODE_EFFECTIVE = VTERMCODE
                            AND sh.shrgrde_passed_ind = 'Y'
                            and  V.SVRSVPR_PROTOCOL_SEQ_NO = (select max (V2.SVRSVPR_PROTOCOL_SEQ_NO)
                                                                from  svrsvpr v2
                                                                  where 1=1
                                                                    and  v2.SVRSVPR_PIDM =  ppidm
                                                                    and  v2.SVRSVPR_SRVC_CODE = pcode
                                                                     and v2.SVRSVPR_SRVS_CODE  NOT IN  ('CA')
                                                                     AND V2.SVRSVPR_STEP_COMMENT = 'NIVE_CERO' 
                                                                       and  v.SVRSVPR_PROTOCOL_AMOUNT = 0  ); 

                     

             EXCEPTION WHEN OTHERS THEN
                  vcuenta_mate2 := 0;
                  vsalida    := 'SI ESTA EN CEROS QUIERE DECIR QUE NO HA PEDIDO LA MATERIA Y LA PUEDE TOMAR';
                 -- DBMS_output.PUT_LINE(VSALIDA );
                  
             end;
             
           ELSE
           
               begin
                    select NVL(count(SVRSVPR_PIDM),0)--- SI regresa "1" quiere decir que la ultima materia de costo cero si esta a probada
                      INTO vcuenta_mate2               -- entonces si puede pedir la segunda en costo cero
                       from sfrstcr f, svrsvpr v,SVRSVAD VA,shrgrde SH
                         where 1=1
                            and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO 
                            and v.SVRSVPR_PIDM = f.SFRSTCR_PIDM
                            and V.SVRSVPR_PROTOCOL_SEQ_NO = f.SFRSTCR_STRD_SEQNO
                            and f.SFRSTCR_PIDM = ppidm
                            and v.SVRSVPR_SRVC_CODE  = pcode
                           -- and f.SFRSTCR_RESERVED_KEY  = pmateria
                            and va.SVRSVAD_ADDL_DATA_SEQ = '2'
                            and v.SVRSVPR_SRVS_CODE  NOT IN  ('CA')
                            AND V.SVRSVPR_STEP_COMMENT = 'NIVE_CERO'
                            and F.SFRSTCR_RSTS_CODE  = 'RE'
                            and substr(F.SFRSTCR_TERM_CODE,5,1)  = '8'
                            and F.SFRSTCR_GRDE_CODE  IN ('7.0','8.0','9.0','10.0') -- valida que la materia anterior sea aprobatoria
                            AND f.SFRSTCR_GRDE_CODE = SH.SHRGRDE_CODE
                            AND f.SFRSTCR_LEVL_CODE = SH.SHRGRDE_LEVL_CODE
                             AND SH.SHRGRDE_TERM_CODE_EFFECTIVE = VTERMCODE
                            AND sh.shrgrde_passed_ind = 'Y'
                            and  V.SVRSVPR_PROTOCOL_SEQ_NO = (select max (V2.SVRSVPR_PROTOCOL_SEQ_NO)
                                                                from  svrsvpr v2
                                                                  where 1=1
                                                                    and  v2.SVRSVPR_PIDM =  ppidm
                                                                    and  v2.SVRSVPR_SRVC_CODE = pcode
                                                                     and v2.SVRSVPR_SRVS_CODE  NOT IN  ('CA')
                                                                     AND V2.SVRSVPR_STEP_COMMENT = 'NIVE_CERO' 
                                                                       and  v.SVRSVPR_PROTOCOL_AMOUNT = 0  ); 

                     

             EXCEPTION WHEN OTHERS THEN
                  vcuenta_mate2 := 0;
                  vsalida    := 'SI ESTA EN CEROS QUIERE DECIR QUE NO HA PEDIDO LA MATERIA Y LA PUEDE TOMAR';
                 -- DBMS_output.PUT_LINE(VSALIDA );
                  
             end;
           
             
           END IF;    
            -- DBMS_output.PUT_LINE('entro en cuenta mate2 >> '||vcuenta_mate2||'--' || VTERMCODE );
             
          END IF;--ESTATUS PA
          
                           
         END IF;
  
 
     
    --2.1 da regla buscamos en doca el valor máximo de adeudo
 
         begin   --- Y  significa que el adeudo es menor que lo configurado en DOCA
            SELECT 'Y'
              INTO vadeudo
                FROM SZTDOCA
                WHERE 1=1
                AND SZT_CODE_ACC = PCODE
                AND SZT_CAMPUS     =  vcampus
                AND SZT_NIVEL        =  vnivel 
                and  SZT_ADEUDO     >=  NVL(BANINST1.PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia_Titulo (ppidm),0);
                
          exception when others then
          vadeudo := 0;
           vsalida    := 'ERROR NO CUMPLE CON ADEUDO';
          -- DBMS_output.PUT_LINE(VSALIDA );
        end;
    
               
          BEGIN--- obtenemos su avance avcu
               SELECT ROUND(nvl(SZTHITA_AVANCE,0))
                  INTO VAVCU
                    FROM SZTHITA ZT
                    WHERE ZT.SZTHITA_PIDM = PPIDM
                    AND    ZT.SZTHITA_LEVL  = Vnivel
                    AND   ZT.SZTHITA_PROG   = PPROGRAMA  ;
                    --DBMS_OUTPUT.PUT_LINE('SALIDA AVANCE HITA  '|| VDESC2);
           EXCEPTION WHEN OTHERS THEN
            VAVCU :=0;
                    BEGIN
                       SELECT ROUND(BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 ( PPIDM, PPROGRAMA ))
                              INTO VAVCU
                         FROM DUAL;

                      --   DBMS_OUTPUT.PUT_LINE('SALIDA AVANCE_DASHBOARD:: '|| VDESC2);
                      EXCEPTION WHEN OTHERS THEN
                       VAVCU :=0;
                       --DBMS_output.PUT_LINE('error en AVCU'||VSALIDA );
                      END;
          END;

         --- segun su avance tiene el beneficio de costo CERO
                BEGIN
                
                  select 'Y'
                    into vavcumat
                      from sztnipr
                       where 1=1
                        and substr(SZT_CODE,1,2)= SUBSTR(F_GetSpridenID(PPIDM),1,2)
                        and  VAVCU  between SZT_MINIMO and SZT_MAXIMO
                        and SZT_CAMPUS = vcampus
                        and SZT_NIVEL =  vnivel
                        AND SZT_PRECIO = 0 ;
                
                
                EXCEPTION WHEN OTHERS THEN
                vavcumat  :='N';
                vsalida := 'erroe en sztnipr'||sqlerrm;
               -- DBMS_output.PUT_LINE('error en NIPR'||VSALIDA );
                END;
                
          
        
         --- REGLA QUE INDOCA QUE NO PUEDE PEDIR MAS DE 2 NIVES CERO X BIMETRE..
         
         BEGIN
           select NVL(COUNT(1),0)
           into V2BIM_NIVE
            from sfrstcr f, svrsvpr v,SVRSVAD VA
             where 1=1
                and f.SFRSTCR_PIDM = PPIDM
                and v.SVRSVPR_SRVC_CODE  = pcode
                and v.SVRSVPR_SRVS_CODE  NOT IN  ('CA')
                AND V.SVRSVPR_STEP_COMMENT = 'NIVE_CERO'
                and F.SFRSTCR_RSTS_CODE  = 'RE'
                and substr(F.SFRSTCR_TERM_CODE,5,1)  = '8'
                and f.SFRSTCR_STRD_SEQNO is not null
                --and F.SFRSTCR_GRDE_CODE  is not null --in ('6.0','7.0','8.0','9.0','10.0' )no importa si es reprobada o acreditada 
                and V.SVRSVPR_PROTOCOL_SEQ_NO  = VA.SVRSVAD_PROTOCOL_SEQ_NO 
                and v.SVRSVPR_PIDM = f.SFRSTCR_PIDM
                and V.SVRSVPR_PROTOCOL_SEQ_NO = f.SFRSTCR_STRD_SEQNO
                and  va.SVRSVAD_ADDL_DATA_SEQ = '2'
                AND SFRSTCR_TERM_CODE  = (SELECT MAX(F2.SFRSTCR_TERM_CODE)
                                                FROM SFRSTCR F2
                                                  WHERE 1=1
                                                    AND f.SFRSTCR_PIDM = f2.SFRSTCR_PIDM 
                                                    and F.SFRSTCR_RSTS_CODE  = 'RE'
                                                    and substr(F.SFRSTCR_TERM_CODE,5,1)  = '8'
                                                    and f.SFRSTCR_STRD_SEQNO is not null
                                                  --  and F.SFRSTCR_GRDE_CODE  is not null --in ('6.0','7.0','8.0','9.0','10.0' )
                                                );

         EXCEPTION WHEN OTHERS THEN
         V2BIM_NIVE:=0;
       --  DBMS_output.PUT_LINE('salida error en calculo de bimestre '||V2BIM_NIVE );
         
          
         END;
         
  ELSE
    VSALIDA := 'MATERIA CON NP';   
    vmax_mate  :='N';  
   -- DBMS_output.PUT_LINE(VSALIDA );
                 
 END IF;---- FIN DE MATERIA np       
          /* DBMS_output.PUT_LINE('salida final matriculado: '|| Vmatriculado ||' - adeudo: '||vadeudo||' - avcu: '|| vavcumat||' - materia con beneficio que reprobo na o 5.0 ' ||vmax_mate
                                ||' -valida 2da materia que la 1ra haya sido aprobada: '||vcuenta_mate2||
                               ' -que no tenga mas de 2 x bimestre: '|| V2BIM_NIVE||' -salida; '||vsalida); */
           
        IF Vmatriculado ='Y' AND  vadeudo ='Y' AND vavcumat ='Y' AND vmax_mate ='Y' AND vcuenta_mate2=1 AND V2BIM_NIVE < 2  THEN 
         --DBMS_output.PUT_LINE('salida final return1  '||vsalida) ;
         RETURN 'EXITO' ;

        ELSE
        vsalida    := 'ERROR No cumple con las reglas' ;
         --DBMS_output.PUT_LINE('salida final return2  '||vsalida) ;
        RETURN vsalida ;
        
       END IF;

   --DBMS_output.PUT_LINE('salida final return  '||vsalida) ;

EXCEPTION WHEN OTHERS THEN 
VSALIDA := 'ERROR GRAL NIVE CERO'||SQLERRM  ;
--DBMS_output.PUT_LINE(VSALIDA );

END F_NIVE_CERO;


FUNCTION F_CURSO_CAMB  RETURN PKG_SERV_SIU.cur_idiomas_type
IS

VSALIDA  VARCHAR2(300);
cur_idiomas  SYS_REFCURSOR;

BEGIN
-- ESTa función regresa los cursos que estan configurados en el parametrizador para Cambridge glovicx 05.10.2023

open cur_idiomas  for
                select ZSTPARA_PARAM_ID,ZSTPARA_PARAM_DESC
                from zstpara
                where 1=1
                and ZSTPARA_MAPA_ID in ('NIV_CAMB');



RETURN cur_idiomas;

EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;


END F_CURSO_CAMB;

FUNCTION F_CURSO_DUOL  RETURN PKG_SERV_SIU.cur_idiomas_type
IS


VSALIDA  VARCHAR2(300);
cur_idiomas  SYS_REFCURSOR;

BEGIN
-- ESTa función regresa los cursos que estan configurados en el parametrizador para cambrieg glovicx 05.10.2023

open cur_idiomas  for
                select ZSTPARA_PARAM_ID,ZSTPARA_PARAM_DESC
                from zstpara
                where 1=1
                and ZSTPARA_MAPA_ID in ('NIV_DUOL');



RETURN cur_idiomas;

EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;


END F_CURSO_DUOL;

FUNCTION F_TIPO_ALIANZA (PPCODE in VARCHAR2 ) RETURN VARCHAR2 IS

VSALIDA VARCHAR2(20);

begin

select distinct SZT_TIPO_ALIANZA 
INTO VSALIDA
from SATURN.SZtgece 
where 1=1
and SZT_CODE_SERV = PPCODE;


RETURN (VSALIDA);

EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;
--DBMS_OUTPUT.PUT_LINE('SALIDA ERROR GRAL FTIPO_ALIANZA'||vsalida);

END F_TIPO_ALIANZA;


FUNCTION F_CURSO_BLEND  RETURN PKG_SERV_SIU.cur_blend_type
IS

VSALIDA  VARCHAR2(300);
cur_blend  SYS_REFCURSOR;

BEGIN
-- ESTa función regresa los cursos que estan configurados en el parametrizador para cambrieg glovicx 05.10.2023

open cur_blend  for
               select ZSTPARA_PARAM_VALOR,ZSTPARA_PARAM_DESC
                    from zstpara
                    where 1=1
                    and ZSTPARA_MAPA_ID in ('UTEL_BLEND');



RETURN cur_blend;

EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;


END F_CURSO_BLEND;

FUNCTION F_CURSO_DPLO  ( ppidm number, pprograma varchar2, pcode varchar2  default null)   RETURN PKG_SERV_SIU.cur_dplo_type
IS

--VSALIDA  VARCHAR2(300);
--cur_dplo  PKG_SERV_SIU.cur_dplo_type;
-- SE HACE UN AJUSTE PARA QUE MANDE  LA PALABRA ERROR A LAS OPCIONES DE LAS PREGUNTAS DE DPLO
--  DE FORMA QUE YA NO PUEDAN COMPRAR EL PRODUCTO SI NO EXISTE DIPLOMADOS GLOVICX 29.04.2025
-- se arregla en sfrtcr para que busque x SP del programa glovicx 16.05.2025

vpidm number:=0;
----
--ppidm number:= 2139;
vcampus  varchar2(4); 
vnivel   varchar2(2);
vprograma  varchar2(15);
vrvoe      varchar2(40);
vsalida    varchar2(200):= 'EXITO';
VETIQUETA  varchar2(6);
vdiploma   varchar2(200);
vcodedtl    varchar2(4);
vvalidam    number:=0;
cadena1    VARCHAR2(4000);
cadena2    VARCHAR2(4000);
elementos1  VARCHAR2(4000);
elemento    VARCHAR2(50);
todosEncontrados BOOLEAN := TRUE;
vencontrados  varchar2(1):= 'Y';
vmateriamaco  VARCHAR2(10);
ite        number:=0;
vpaso       VARCHAR2(1):= 'Y';
vsp         number:=0;

cur_dplo  SYS_REFCURSOR;

        
        
BEGIN
vpidm := ppidm;



   begin
       delete twpasow
        where 1=1
          and valor1 = to_char(ppidm)
           and valor4 = 'DPLO';
    
    
    exception when others then
    vsalida := sqlerrm;
      --dbms_output.put_line('error al borra la tabla de paso:  '|| vsalida );
    
    end;

------- aqui tengo que sacar datos grales y promraga para saber su rvoe

    begin
        select t1.campus, t1.nivel, t1.programa, T1.SP
             INTO  vcampus, vnivel, vprograma, vsp
          from tztprog t1
           where 1=1
             and t1.pidm = ppidm
             --and t1.sp    = jump.sp
             and T1.PROGRAMA = pprograma   ;  
     exception when others then
      vcampus:= null; 
      vnivel:= null; 
      vprograma:= null;
      vsp     := 1;
    
    end;


    IF vprograma is null then 
        
            begin
                    select distinct  G1.SGBSTDN_CAMP_CODE, g1.SGBSTDN_LEVL_CODE,  G1.SGBSTDN_PROGRAM_1 
                        INTO  vcampus, vnivel, vprograma
                         from sgbstdn g1
                          where 1=1
                            and g1.SGBSTDN_PIDM =   ppidm
                            and g1.SGBSTDN_TERM_CODE_EFF = (select max (g2.SGBSTDN_TERM_CODE_EFF)
                                                                from sgbstdn g2
                                                                   where 1=1
                                                                    and  g1.SGBSTDN_PIDM = g2.SGBSTDN_PIDM )  ;
            exception when others then
              vcampus:= null; 
              vnivel:= null; 
              vprograma:= null;
            
            end;
  
     end if;

      ----  con el programa buscamos el rvoe
       begin
           select distinct  SZTDTEC_NUM_RVOE 
             INTO vrvoe
                from sztdtec d1
                   where 1=1
                        and d1.SZTDTEC_NUM_RVOE is not null
                        and d1.SZTDTEC_PROGRAM = pprograma
                        and d1.SZTDTEC_FECHA_RVOE = (select max(d2.SZTDTEC_FECHA_RVOE)
                                                                               from sztdtec d2
                                                                                 where 1=1
                                                                                   and d1.SZTDTEC_NUM_RVOE is not null
                                                                                    and d2.SZTDTEC_PROGRAM = d1.SZTDTEC_PROGRAM  ) ;
       exception when others then
        vrvoe := 'NA';
        vsalida  := sqlerrm;
        -- dbms_output.put_line('errro no se consiguio el número de rvoe  '|| vsalida  );
       
       end;
  

for jump in (
        select DISTINCT  f.SFRSTCR_PIDM pidm, 
        bb.SSBSECT_SUBJ_CODE||bb.SSBSECT_CRSE_NUMB materia, 
       -- f.SFRSTCR_RESERVED_KEY   materia,
        f.SFRSTCR_STSP_KEY_SEQUENCE sp
        from sfrstcr f, ssbsect bb
        where 1=1
        and F.SFRSTCR_CRN  = BB.SSBSECT_CRN
        and F.SFRSTCR_TERM_CODE  = BB.SSBSECT_TERM_CODE
        and f.SFRSTCR_PIDM = NVL(vpidm, f.SFRSTCR_PIDM)
        and F.SFRSTCR_RSTS_CODE  = 'RE'
        --and F.SFRSTCR_GRDE_CODE  != '5.0'
        and F.SFRSTCR_GRDE_CODE NOT IN ('5.0', 'NP','NA')
        AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%H%')
        AND  BB.SSBSECT_SUBJ_CODE||BB.SSBSECT_CRSE_NUMB NOT LIKE('%SESO%') 
        and F.SFRSTCR_STSP_KEY_SEQUENCE  =   VSP  ---- ESTO ES PARA GENERE X SP  -- ajuste jira 21.05.2025
       /* and F.SFRSTCR_STSP_KEY_SEQUENCE  = (select max (f2.SFRSTCR_STSP_KEY_SEQUENCE)
                                                                     from sfrstcr f2 
                                                                        where 1=1 
                                                                          and  f.SFRSTCR_PIDM =  f2.SFRSTCR_PIDM )
                                                                      */    
        --and rownum <= 10
        ORDER BY materia 
        )  loop
        null;
       
         ---  aqui metemos la conversión de la materia hija a la materia padre de MACO glovicx 17.04.2024
         begin
              select distinct SZTMACO_MATPADRE
                into vmateriamaco  
                 from sztmaco
                 where 1=1
                 and SZTMACO_MATHIJO = JUMP.MATERIA  ;
                 
         exception when others then        
           vmateriamaco :=  JUMP.MATERIA;
           vsalida  := sqlerrm;
          --dbms_output.put_line('ERRORR EN CONVERSION MACO  '||JUMP.MATERIA ||'->>>'|| vsalida  );
         end;
         
         
      ---- aqui lanzamos el otro for para ir buscando en la configuración que diplomas le corresponde
     cadena2 :=  cadena2 ||','|| vmateriamaco;
        

end loop;
--dbms_output.put_line('campus nivel prog RVOEE   '|| vcampus||'-'|| vnivel||'-'|| vprograma||'-'||vrvoe );
 --dbms_output.put_line('salida loop cadena2  '|| cadena2 );
 
   FOR onn  IN (select distinct 
                       replace(gr.SZT_MATERIAS_REQ,'''') materias,
                       gr.SZT_ETIQUETA etiqueta,  gr.SZT_DIPLOMA diploma, GR.SZT_SEQ seq1 --, SZT_CODE_DTL code_dtl 
                            from SZTDIGR gr
                            where 1=1
                             and gr.szt_rvoe = vrvoe 
                             and gr.SZT_ETIQUETA Not in (select DISTINCT GORADID_ADDITIONAL_ID
                                                                from goradid
                                                                where 1=1
                                                                AND GORADID_DATA_ORIGIN = 'DPLO'
                                                                AND GORADID_PIDM  = ppidm
                                                                 )
                              order by GR.SZT_SEQ 

                                                     )  LOOP
            cadena1    := onn.materias;
            VETIQUETA   :=onn.etiqueta;
            vdiploma      :=onn.diploma;
           -- vcodedtl       :=onn.code_dtl;
           
            elemento     := NULL;
            
               
            BEGIN
                    elementos1 := cadena1;
                   -- DBMS_OUTPUT.PUT_LINE('Todos lOS elementos- : '||vvalidam||'----'|| elementos1 );
                    
                    -- Itera sobre cada elemento en cadena1
                    LOOP
                        EXIT WHEN elementos1 IS NULL;
                        
                   -- Obtiene el primer elemento de elementos1
                    IF INSTR(elementos1, ',') > 0 THEN
                        elemento := TRIM(SUBSTR(elementos1, 1, INSTR(elementos1, ',') - 1));
                      --  DBMS_OUTPUT.PUT_LINE('Todos lOS RENGLONESAAAAAAA: '|| elementos1|| '-->>>'||elemento);
                      --  DBMS_OUTPUT.PUT_LINE('Todos lOS RENGLONESOOOOOO: '|| elemento    );
                    ELSE
                        elemento := TRIM(elementos1);
                        
                      --  DBMS_OUTPUT.PUT_LINE('ULTIMO ELEMENTO DE  la cadena: '|| elementos1|| '-->>>'||elemento||'-'|| ite);
                        
                    END IF;
                    
                    -- DBMS_OUTPUT.PUT_LINE('ANTES DE COMPARAR cadena eleento: '|| cadena2|| '-->>>'||elemento||'-'|| ite);
                    -- Verifica si el elemento existe en cadena2 -- IGUAL A CERO SIGNIFICA QUE NO ESTA EL ELEMENTO EN LA CADENA
                    IF INSTR(',' || cadena2 || ',', ',' || TRIM(elemento) || ',') = 0 THEN
                        todosEncontrados := FALSE;
                        vencontrados  := 'N';
                      --  DBMS_OUTPUT.PUT_LINE('Todos lOS RENGLONESQQQQQQ.'|| elementos1||'/-/'|| elemento ||'-'||vencontrados   );
                        EXIT;
                    END IF;
                    
                    -- Elimina el elemento procesado de elementos1
                    IF INSTR(elementos1, ',') > 0 THEN
                        elementos1 := SUBSTR(elementos1, INSTR(elementos1, ',') + 1);
                       -- DBMS_OUTPUT.PUT_LINE('Todos lOS RENGLONES xxx: '|| elementos1||'->>>>'|| elemento    );
                     --   DBMS_OUTPUT.PUT_LINE('Todos lOS RENGLONES MMM: '|| elemento    );
                    ELSE
                        elementos1 := NULL;
                     --   DBMS_OUTPUT.PUT_LINE('Todos lOS RENGLONES ZZZZZ: '|| elementos1||'->>>>'|| elemento    );
                    END IF;
                    ite := ite + 1; -- aqui va contando las iteraciones exitosas para el array
                   -- DBMS_OUTPUT.PUT_LINE('Cadena disminuida .'|| elementos1||'-'|| elemento    );
                    EXIT WHEN elementos1 IS NULL;
                    
                    --DBMS_OUTPUT.PUT_LINE('Todos lOS RENGLONES.'|| elementos1||'-'|| elemento    );
                END LOOP;
                
                -- Resultado
              --  DBMS_OUTPUT.PUT_LINE('Todos encontrados.'|| vencontrados    );
                
                IF vencontrados = 'Y' THEN
                  --  DBMS_OUTPUT.PUT_LINE('EXITO todos elementos de cadena1 están en cadena2.'|| vdiploma||'-'|| VETIQUETA );
                    -------aqui va el proceso de insert a la nueva tabla szqrdi.   
                  -- aqui se llena el cursor
                     
                     -- cur_dplo(i).uno := VETIQUETA; 
                    --  cur_dplo(i).dos := vdiploma;
                  begin   
                   
                    insert into twpasow (valor1,valor2,valor3, valor4,valor5, VALOR6, valor7,valor8)
                    values  (to_char(ppidm),VETIQUETA,onn.seq1, 'DPLO', vdiploma,pprograma, trunc(sysdate),pcode );
                  
                   exception when others then
                   null;
                     --DBMS_OUTPUT.PUT_LINE('Error en INsert twpaso DPLO.' || sqlerrm  );
                   end; 
                    
                ELSE
                NULL;
                  --  DBMS_OUTPUT.PUT_LINE('No todos los elementos de cadena1 están en cadena2x.');
                END IF;
                
                
            EXCEPTION WHEN OTHERS THEN    
            vsalida := sqlerrm;
              --   DBMS_OUTPUT.PUT_LINE('Error en la función de contar las cadenas '|| vsalida );
            END;
            
              vvalidam := vvalidam +1;
                 
        -- dbms_output.put_line('salida loop  PRINCIPAL  '|| '-'|| vencontrados );
             
               vencontrados := 'Y';
        end loop;

        --- si no hay datos en la tabla quiere decir que NO cumple con ningu rango para comprar diplomas
        --  entonces mandamos el cursor como error.
        
            begin
                  select distinct 'Y'
                   INTO vpaso
                      from twpasow
                        where 1=1
                          and valor1 = to_char(ppidm) 
                          and valor4 = 'DPLO';
            
             EXCEPTION WHEN OTHERS THEN    
            vsalida := sqlerrm;
            vpaso   := 'N';
               --  DBMS_OUTPUT.PUT_LINE('Error en la función de contar las cadena '|| vsalida );
            end;
          --  DBMS_OUTPUT.PUT_LINE('saliendo de la validacion twpaso '|| vpaso );
            
   IF  vpaso = 'N'  then     

        open cur_dplo  FOR 
                    select 'ERROR' as valor1,
                           'ERROR' as valor2
                      from dual;
                 
   ELSE 
        open cur_dplo  FOR 
                 select valor2,valor5
                      from twpasow
                        where 1=1
                          and valor1 = to_char(ppidm) 
                           and valor4 = 'DPLO'
                           and valor2 NoT IN (
                                                select DISTINCT GORADID_ADDITIONAL_ID
                                                from goradid
                                                  where 1=1
                                                AND GORADID_DATA_ORIGIN = 'DPLO'
                                                AND GORADID_PIDM  = To_char(ppidm)
                                                )
                           order by 1;


    end if;



RETURN cur_dplo;


EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;
--dbms_output.put_line('error gral curso_dplo:  '|| vsalida );
end F_CURSO_DPLO;



FUNCTION F_CURSO_IDIOMAS  ( ppidm number, pprograma varchar2, pcode varchar2  default null)   
RETURN PKG_SERV_SIU.cur_idiomas_type
IS
/*
ESTA función es para regresar los datos de la pregunta 11 del auto servicio para las certificaciones
de idiomas aqui se pueden ir poniendo mas idiomas cursores glovicx 16.04.2024
*/

VSALIDA  VARCHAR2(300);
cur_idiomas  SYS_REFCURSOR;


BEGIN
NULL;


IF pcode = 'CTVT'  THEN
   
    open cur_idiomas  FOR 
        select ZSTPARA_PARAM_ID,ZSTPARA_PARAM_DESC
        from zstpara
        where 1=1
        and ZSTPARA_MAPA_ID = 'NIV_VTEST';

   RETURN cur_idiomas;

elsif pcode = 'SKIL'  THEN

      open cur_idiomas  FOR 
        select ZSTPARA_PARAM_ID,ZSTPARA_PARAM_DESC
        from zstpara
        where 1=1
        and ZSTPARA_MAPA_ID = 'NIV_LINGUASKILL';

  RETURN cur_idiomas;


END IF;


EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;
--dbms_output.put_line('error gral curso_idiomas :  '|| vsalida );

END F_CURSO_IDIOMAS;

FUNCTION F_TIPO_ENVIO  (PPIDM NUMBER)  RETURN PKG_SERV_SIU.cur_envios_type
IS

VSALIDA  VARCHAR2(300);
cur_envios  SYS_REFCURSOR;

BEGIN
-- ESTa función regresaLOS TIPOS DE envio x pais y costo,  PROYECTO ENIN_v2 glovicx 16.12.2024

open cur_envios  for
               SELECT  ZSTPARA_PARAM_VALOR code_dtl, ZSTPARA_PARAM_DESC ||' $ '|| TBBDETC_AMOUNT costo   
                   FROM ZSTPARA z, TBBDETC t1
                     WHERE 1=1
                      AND z.ZSTPARA_MAPA_ID  = 'TIPO_ENVIO'
                      and z.ZSTPARA_PARAM_VALOR = TBBDETC_DETAIL_CODE
                      and substr(Z.ZSTPARA_PARAM_VALOR,1,2) = SUBSTR(F_GetSpridenID(PPIDM),1,2);



RETURN cur_envios;

EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;
RETURN cur_envios;
dbms_output.put_line('salida error gral: '|| vsalida  );

END F_TIPO_ENVIO;

FUNCTION F_ENVIO_DOCS  RETURN PKG_SERV_SIU.cur_envidocs_type
IS

VSALIDA  VARCHAR2(300);
cur_envidocs  SYS_REFCURSOR;

BEGIN
-- ESTa funcion regresa los tipos de accesorios que se pueden enviar x paqueteria PROYECTO ENIN glovicx 16.12.2024


open cur_envidocs  for
               select ZSTPARA_PARAM_VALOR,ZSTPARA_PARAM_DESC
                    from zstpara
                    where 1=1
                    and ZSTPARA_MAPA_ID in ('ENVIO_DOCS');



RETURN cur_envidocs;

EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;


END F_ENVIO_DOCS;


FUNCTION F_DIRECCION_PQT (PPIDM NUMBER, PATYP_CODE VARCHAR2 DEFAULT NULL ) RETURN SYS_REFCURSOR
IS

VSALIDA        VARCHAR2(300);
cur_atyp       SYS_REFCURSOR;
cur_domicilio  SYS_REFCURSOR;

vtatyp       varchar2(4); 
vdomicilio   varchar2(40);

BEGIN
-- ESTa funcion regresa la direccion del alumno segun su codigo
--  esta funcion tiene 2 funciones 
-- 1ra mostrar las direcciones que tiene el alumno en la bd
IF PATYP_CODE is null THEN
    
     /*     -- se quita esta seccion NO hace nada NO tiene razón
        begin
            
            SELECT t.STVATYP_CODE, t.STVATYP_DESC
                INTO vtatyp, vdomicilio
                 from SPRADDR r, STVATYP t
                 where 1=1
                  and r.SPRADDR_PIDM = PPIDM
                  and R.SPRADDR_ATYP_CODE = t.STVATYP_CODE
                  and t.STVATYP_CODE  != 'NA'; --regla de Fer se quita las direcciones de Nacimiento.
                  
        exception when others then         
          vtatyp  := ''; 
          vdomicilio  := '';
          
        end;
  */      
        
-----AQUI REGRESA EL CURSOR CON LAS DIRECCIONES REGISTRADAS DEL ALUMNO
                
        open cur_atyp  for
                        SELECT rownum,t.STVATYP_CODE, t.STVATYP_DESC
                           from SPRADDR r, STVATYP t
                             where 1=1
                              and r.SPRADDR_PIDM = PPIDM
                              and R.SPRADDR_ATYP_CODE = t.STVATYP_CODE
                               and t.STVATYP_CODE  != 'NA'  --regla de Fer se quita las direcciones de Nacimiento.
                              union
                              select 6,'Otro','Otro'
                              from dual
                              where 1=1
                              order by 1;



        RETURN cur_atyp;

ELSE
 -- aqui regresa todos los datos de la dirección 
     OPen  cur_domicilio    FOR
                SELECT SPRADDR_STREET_LINE1 calle_num,
                       SPRADDR_STREET_LINE3 colonia,
                       SPRADDR_CITY ciudad,
                       SPRADDR_CNTY_CODE municipio,
                       SPRADDR_STAT_CODE  estado,
                       SPRADDR_NATN_CODE  pais,
                       SPRADDR_ZIP  cp
                  from SPRADDR r, STVATYP t
                     where 1=1
                      and R.SPRADDR_ATYP_CODE = t.STVATYP_CODE
                      and r.SPRADDR_PIDM = PPIDM
                      and r.SPRADDR_ATYP_CODE   = PATYP_CODE ;
 
      RETURN cur_domicilio;

END IF;



EXCEPTION WHEN OTHERS THEN
NULL;
vsalida := sqlerrm;

--dbms_output.put_line(' Error general en la funcion F_DIRECCION_PQT:   '||  vsalida );

END F_DIRECCION_PQT;


PROCEDURE P_QUITA_CARGO_NIVE (PPIDM number, PSEQNO number) IS
/* ESTE PROCESO SE BASA EN BUSCAR EL UNIVERSO DE QUIEN ADQUIRIO ALGUNA NIVE COSTO CERO
ESTE PROCESO SE EJECUTA DESDE UN JOB PARA IR VALIDANDO LAS REGLAS:
CREATE GLOVICX 15.08.2024

*/


VSALIDA varchar2(5000):= 'EXITO';
vl_transaccion number;
VL_DESCRIPCION varchar2(50):= null;
vl_Cargo varchar2(4):= null;
vl_moneda varchar2(4):= null;
vl_monto number;





Begin

        For cx in (
        
                    select V.SVRSVPR_SRVC_CODE Codigo, V.SVRSVPR_PIDM PIDM , Va.SVRSVAD_PROTOCOL_SEQ_NO SEQNO, Va.SVRSVAD_ADDL_DATA_CDE MATERIA,
                     V.SVRSVPR_TERM_CODE Periodo_Venta, SFRSTCR_STRD_SEQNO Seq_Horario, 
                     case when trim (SFRSTCR_GRDE_CODE) is null then 
                     'EC' 
                     when trim (SFRSTCR_GRDE_CODE) is not null then 
                       trim (SFRSTCR_GRDE_CODE) 
                       End   Calif, 
                       SSBSECT_PTRM_START_DATE Fecha_inicio, SSBSECT_VPDI_CODE Orden, 
                     SFRSTCR_TERM_CODE Periodo, SFRSTCR_CRN CRN, SFRSTCR_PTRM_CODE Pperiodo, 
                     spriden_id matricula, 
                     SFRSTCR_STSP_KEY_SEQUENCE Sp, 
                     TBRACCD_TRAN_NUMBER Trans_cargo, 
                     tbraccd_amount Monto
                    from svrsvpr v
                    join SVRSVAD VA on VA.SVRSVAD_PROTOCOL_SEQ_NO = V.SVRSVPR_PROTOCOL_SEQ_NO and VA.SVRSVAD_ADDL_DATA_SEQ = 2
                    join spriden on spriden_pidm = v.SVRSVPR_PIDM and spriden_change_ind is null
                    join sfrstcr on sfrstcr_pidm = v.SVRSVPR_PIDM and substr(SFRSTCR_TERM_CODE,5,1)  = '8' and SFRSTCR_STRD_SEQNO = SVRSVAD_PROTOCOL_SEQ_NO
                    join ssbsect on SSBSECT_TERM_CODE =  SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB = SVRSVAD_ADDL_DATA_CDE
                    join tbraccd on tbraccd_pidm = spriden_pidm and TBRACCD_CROSSREF_NUMBER = SVRSVAD_PROTOCOL_SEQ_NO
                      where 1=1
                        ANd V.SVRSVPR_SRVC_CODE = 'NIVE'
                        AND V.SVRSVPR_SRVS_CODE = 'EC'
                        and V.SVRSVPR_STEP_COMMENT = 'NIVE_CERO'
                        And V.SVRSVPR_PIDM    = NVL(PPIDM,V.SVRSVPR_PIDM )
                        AND V.SVRSVPR_PROTOCOL_SEQ_NO = NVL(PSEQNO,V.SVRSVPR_PROTOCOL_SEQ_NO ) 
                       -- order by 1 desc
        ) loop
        
        VSALIDA:= 'EXITO';
        
        If cx.calif ='NP' then 
        
             BEGIN
              UPDATE  SVRSVPR  v
                SET v.SVRSVPR_SRVS_CODE = 'PP',  ---> pendiente de Pago
                    V.SVRSVPR_ACTIVITY_DATE = SYSDATE
                  WHERE 1=1
                    ANd  V.SVRSVPR_SRVC_CODE = cx.codigo
                    and  V.SVRSVPR_PIDM      = cx.PIDM
                    and  V.SVRSVPR_PROTOCOL_SEQ_NO  = cx.SEQNO
                    and  V.SVRSVPR_STEP_COMMENT = 'NIVE_CERO' ;
              EXCEPTION WHEN OTHERS THEN  
                VSALIDA:= 'Se presento un error al actualizar el servicio en la tabla SVRSVPR 1'|| sqlerrm;
                 dbms_output.PUT_LINE('ERROR: '||VSALIDA  );
             END;        
        
        
        Elsif cx.calif ='EC' then
            null;  ---> No hace nada porque la materia esta en Curso
        
        Elsif cx.calif not in ('NP', 'EC') then
        
             BEGIN
              UPDATE  SVRSVPR  v
                SET v.SVRSVPR_SRVS_CODE = 'EN',  --> ENTREGADO O ENVIADO
                    V.SVRSVPR_ACTIVITY_DATE = SYSDATE
                  WHERE 1=1
                    ANd  V.SVRSVPR_SRVC_CODE = cx.codigo
                    and  V.SVRSVPR_PIDM      = cx.PIDM
                    and  V.SVRSVPR_PROTOCOL_SEQ_NO  = cx.SEQNO
                    and  V.SVRSVPR_STEP_COMMENT = 'NIVE_CERO' ;
              EXCEPTION WHEN OTHERS THEN  
                VSALIDA:= 'Se presento un error al actualizar el servicio en la tabla SVRSVPR 2'|| sqlerrm;
               dbms_output.PUT_LINE('ERROR: '||VSALIDA  );
             END;        
        

             VL_TRANSACCION:=0;
             BEGIN
                SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) +1
                    INTO VL_TRANSACCION
                FROM TBRACCD
                WHERE TBRACCD_PIDM=cx.pidm;
             EXCEPTION
             WHEN OTHERS THEN
                VL_TRANSACCION:=0;
             END;  
         

            VL_DESCRIPCION := null;
            vl_Cargo := null;
            vl_moneda := null;
            vl_monto := null;


            Begin
                  Select TBBDETC_DETAIL_CODE, TBBDETC_DESC, TVRDCTX_CURR_CODE, TBBDETC_AMOUNT
                    Into vl_cargo, VL_DESCRIPCION, vl_moneda, vl_monto
                 from tbbdetc
                 join tvrdctx on  TVRDCTX_DETC_CODE = tbbdetc_detail_code
                 where tbbdetc_detail_code = substr (cx.matricula,1,2)||'OP';  ---> Codigo de Detalle para aplicar el ajuste de Colegiatura
              Exception
                When Others then 
                    VL_DESCRIPCION := null;
                    vl_Cargo := null;
                    vl_moneda := null;
                    vl_monto := null;
            End;  
            
                                          
                                
            BEGIN
                       INSERT INTO TBRACCD
                       VALUES (
                               cx.PIDM,                                         -- TBRACCD_PIDM
                               VL_TRANSACCION,                                     -- TBRACCD_TRAN_NUMBER
                               cx.PERIODO_VENTA,                                      -- TBRACCD_TERM_CODE
                               vl_Cargo,                                         -- TBRACCD_DETAIL_CODE
                               USER,                                               -- TBRACCD_USER
                               SYSDATE,                                            -- TBRACCD_ENTRY_DATE
                               NVL(cx.monto,0),                                 -- TBRACCD_AMOUNT
                               NVL(cx.monto,0)*-1,                            -- TBRACCD_BALANCE
                               SYSDATE,                                            -- TBRACCD_EFFECTIVE_DATE
                               NULL,                                               -- TBRACCD_BILL_DATE
                               NULL,                                               -- TBRACCD_DUE_DATE
                               VL_DESCRIPCION,                                     -- TBRACCD_DESC
                               cx.orden,                                        -- TBRACCD_RECEIPT_NUMBER
                               cx.TRANS_CARGO,                                        -- TBRACCD_TRAN_NUMBER_PAID
                               NULL,                                               -- TBRACCD_CROSSREF_PIDM
                               NULL,                                               -- TBRACCD_CROSSREF_NUMBER
                               NULL,                                               -- TBRACCD_CROSSREF_DETAIL_CODE
                               'T',                                                -- TBRACCD_SRCE_CODE
                               'Y',                                                -- TBRACCD_ACCT_FEED_IND
                               SYSDATE,                                            -- TBRACCD_ACTIVITY_DATE
                               0,                                                  -- TBRACCD_SESSION_NUMBER
                               NULL,                                               -- TBRACCD_CSHR_END_DATE
                               NULL,                                               -- TBRACCD_CRN
                               NULL,                                               -- TBRACCD_CROSSREF_SRCE_CODE
                               NULL,                                               -- TBRACCD_LOC_MDT
                               NULL,                                               -- TBRACCD_LOC_MDT_SEQ
                               NULL,                                               -- TBRACCD_RATE
                               NULL,                                               -- TBRACCD_UNITS
                               NULL,                                               -- TBRACCD_DOCUMENT_NUMBER
                               SYSDATE,                                            -- TBRACCD_TRANS_DATE
                               NULL,                                               -- TBRACCD_PAYMENT_ID
                               NULL,                                               -- TBRACCD_INVOICE_NUMBER
                               NULL,                                               -- TBRACCD_STATEMENT_DATE
                               NULL,                                               -- TBRACCD_INV_NUMBER_PAID
                               vl_moneda,                                              -- TBRACCD_CURR_CODE
                               NULL,                                               -- TBRACCD_EXCHANGE_DIFF
                               NULL,                                               -- TBRACCD_FOREIGN
                               NULL,                                               -- TBRACCD_LATE_DCAT_CODE
                               cx.Fecha_inicio,                              -- TBRACCD_FEED_DATE
                               NULL,                                               -- TBRACCD_FEED_DOC_CODE
                               NULL,                                               -- TBRACCD_ATYP_CODE
                               NULL,                                               -- TBRACCD_ATYP_SEQNO
                               NULL,                                               -- TBRACCD_CARD_TYPE_VR
                               NULL,                                               -- TBRACCD_CARD_EXP_DATE_VR
                               NULL,                                               -- TBRACCD_CARD_AUTH_NUMBER_VR
                               NULL,                                               -- TBRACCD_CROSSREF_DCAT_CODE
                               NULL,                                               -- TBRACCD_ORIG_CHG_IND
                               NULL,                                               -- TBRACCD_CCRD_CODE
                               NULL,                                               -- TBRACCD_MERCHANT_ID
                               NULL,                                               -- TBRACCD_TAX_REPT_YEAR
                               NULL,                                               -- TBRACCD_TAX_REPT_BOX
                               NULL,                                               -- TBRACCD_TAX_AMOUNT
                               NULL,                                               -- TBRACCD_TAX_FUTURE_IND
                               'AUTOMATICO',                                       -- TBRACCD_DATA_ORIGIN
                               'AUTOMATICO',                                       -- TBRACCD_CREATE_SOURCE
                               NULL,                                               -- TBRACCD_CPDT_IND
                               NULL,                                               -- TBRACCD_AIDY_CODE
                               cx.sp,                    -- TBRACCD_STSP_KEY_SEQUENCE
                               null,                               -- TBRACCD_PERIOD
                               NULL,                                               -- TBRACCD_SURROGATE_ID
                               NULL,                                               -- TBRACCD_VERSION
                               USER,                                               -- TBRACCD_USER_ID
                               NULL );                                             -- TBRACCD_VPDI_CODE                                
            Exception
                When Others then 
                    VSALIDA:= 'Se presento un error al insertar el pago en tbraccd'|| sqlerrm;
                     dbms_output.PUT_LINE('ERROR: '||VSALIDA  );
            End;       
        
        End if;
        
        If VSALIDA = 'EXITO' then
          Commit;
        Else 
           rollback;
        End if;
        
    End Loop;         
                    


END P_QUITA_CARGO_NIVE;

FUNCTION f_opci_titulacion (ppidm  number, pprograma varchar2  ) RETURN PKG_SERV_SIU.cursor_opci_titulacion --  FER V1 20/11/2024
 AS 
regist_opci_titulacion PKG_SERV_SIU.cursor_opci_titulacion;
                  
                  
vl_existe   number:= 0;
P_ADID_ID   varchar2(4):= 'ATIN';
v1er_compra varchar2(1):= 'N';
vcosto      varchar2(12):= 0;
vcero       number:= 0;   
VPROGRAMA   varchar2(12);
Vnivel      varchar2(3);
Vcampus      varchar2(4);


-- ajuste glovicx 02.12.2024 este proceso es para DTMA cientifica glovicx 12.03.2025
               
 BEGIN
  --dbms_output.put_line('INIcio opcions   ' );
        ---- se valida si tiene la etiqueta ATIN   glovicx 29.11.2024
        Begin
        
            Select count(1)
                Into vl_existe
                from GENERAL.GORADID
            Where GORADID_PIDM = ppidm
            And GORADID_ADID_CODE  = P_ADID_ID;
            
         Exception  When Others then
            vl_existe :=0;
         End;
        
        --- se valida si es su primer compra  
        begin
            select 'N', SVRSVAD_ADDL_DATA_CDE  --si tiene N es que ya existe una compra DTMA
              INTO v1er_compra, VPROGRAMA
               from svrsvpr v,SVRSVAD VA
                where 1=1
                  and V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                  ANd V.SVRSVPR_SRVC_CODE  = 'DTMA'
                  and v.SVRSVPR_SRVS_CODE NOT in ('CA')
                  and v.SVRSVPR_PIDM  = ppidm
                  and v.SVRSVPR_STEP_COMMENT = 'DTMA_CERO'
                  and SVRSVAD_ADDL_DATA_SEQ = 1
                  ;
        exception when others then 
        v1er_compra  := 'Y'; --- es su primer compra con Y
        VPROGRAMA  := '';
          --DBMS_oUTPUT.PUT_LINE(' ERROR EN 1 DTMA '|| SQLERRM );
        end;
        
          --DBMS_oUTPUT.PUT_LINE(' despues de EN 1 DTMA '|| VPROGRAMA||'-'||v1er_compra );
        
        begin
                      
          select TBBDETC_AMOUNT
            INTO  vcosto
           from TBBDETC
            Where 1=1 
             And TBBDETC_DETAIL_CODE = SUBSTR(F_GetSpridenID(PPIDM),1,2)||'70';--esta es regla todos terminan en 70
         
        exception when others then     
          vcosto := 0;
          --DBMS_oUTPUT.PUT_LINE(' ERROR EN 2 costo  DTMA '|| SQLERRM );
        end;
        
        
       BEGIN
                
          SELECT t.nivel, t.campus
             INTO Vnivel, vcampus
          FROM TZTPROG T
           WHERE 1=1
            AND T.PIDM = PPIDM
            AND T.PROGRAMA = pprograma  ;
      
      
        EXCEPTION WHEN OTHERS THEN
       null;
       
           begin
               SELECT t1.nivel, t1.campus
                     INTO Vnivel, vcampus
                  FROM TZTPROG T1
                   WHERE 1=1
                    AND T1.PIDM = PPIDM
                    AND T1.sp = (select max (t2.sp) 
                                  from  tztprog t2
                                   Where 1=1
                                    and  T2.PIDM  =  T1.PIDM  )  ;
            EXCEPTION WHEN OTHERS THEN
           vcampus := '';
           Vnivel := '';
           --dbms_output.put_line('error en tztprog 1x '|| sqlerrm );
           end;
       
       
        --VSALIDA := SQLERRM;
       -- dbms_output.put_line('error en tztprog 2x '||  sqlerrm );
      END;   
     
       -- dbms_output.put_line('antes de la validacion MAx  '|| vl_existe||'-'||v1er_compra||'-'||Vnivel  );
 
      -- si existe la etiqueta entonces y si tiene una compra anterior entonces 
      IF vl_existe >= 1 and v1er_compra = 'Y'  then  
         -- se ajusta la regla por que hay 2 parametrizadores x nivel
        
        IF  Vnivel = 'MA' then  --para maestria tenemos 2 caso 1 sin precio y otro con precio
        
      
        vcero := 0;
           
          -- dbms_output.put_line('INIcio opcions MA  '|| vcero||'-'|| vl_existe||'-'||v1er_compra||'-'||Vnivel  );
       
             OPEN regist_opci_titulacion FOR
                     SELECT substr(ZSTPARA_PARAM_DESC,instr(ZSTPARA_PARAM_DESC,',',1)+1,10) mate, ZSTPARA_PARAM_DESC||' $ '||vcero
                        FROM zstpara 
                        WHERE 1=1
                        AND ZSTPARA_MAPA_ID= 'ASE_TITULACION'
                        and ZSTPARA_PARAM_ID  in (SELECT ZSTPARA_PARAM_ID
                                                    FROM zstpara 
                                                    WHERE 1=1
                                                     AND ZSTPARA_MAPA_ID= 'ASE_TITULACION'
                                                    AND ZSTPARA_PARAM_VALOR= 'SIN COSTO')
                 UNION
                      SELECT substr(ZSTPARA_PARAM_DESC,instr(ZSTPARA_PARAM_DESC,',',1)+1,10) mate, ZSTPARA_PARAM_DESC||' $ '||vcosto
                        FROM zstpara 
                        WHERE 1=1
                        AND ZSTPARA_MAPA_ID= 'ASE_TITULACION'
                        and ZSTPARA_PARAM_ID in (SELECT ZSTPARA_PARAM_ID
                                                    FROM zstpara 
                                                    WHERE 1=1
                                                     AND ZSTPARA_MAPA_ID= 'ASE_TITULACION'
                                                    AND ZSTPARA_PARAM_VALOR= 'CON COSTO');
        --dbms_output.put_line('primera  opcion de titulo   Maestria');
        
        else  
           --- aqui es para doctororado si tiene etiqueta y si es su primer compra
           -- se presenta 
          OPEN regist_opci_titulacion FOR
               SELECT  substr(ZSTPARA_PARAM_DESC, instr(ZSTPARA_PARAM_DESC,',',1  )+1,10 )  mate, ZSTPARA_PARAM_DESC||' $ '||vcosto
                 FROM zstpara 
                  WHERE 1=1
                    AND ZSTPARA_MAPA_ID= 'ASE_TITULA_DO'
                    and substr(ZSTPARA_PARAM_ID, instr(ZSTPARA_PARAM_ID,',',1  )+1,4 ) = vcampus
                    and ZSTPARA_PARAM_VALOR = 'CON COSTO' 
             UNION
                SELECT  substr(ZSTPARA_PARAM_DESC, instr(ZSTPARA_PARAM_DESC,',',1  )+1,10 )  mate, ZSTPARA_PARAM_DESC||' $ '||vcero
                 FROM zstpara 
                  WHERE 1=1
                    AND ZSTPARA_MAPA_ID= 'ASE_TITULA_DO'
                    and substr(ZSTPARA_PARAM_ID, instr(ZSTPARA_PARAM_ID,',',1  )+1,4 ) = vcampus
                    and ZSTPARA_PARAM_VALOR = 'SIN COSTO' ;
                
          --dbms_output.put_line('segunda opcion de titulo doctorado'|| vl_existe||'-'||v1er_compra||'-'||Vnivel );
        
        
        end if;       
             
       ELSE  ---- aqui espara NO TIENEN etiqueta 1 o mas compras todos dene de salir con costo
            -- dbms_output.put_line('tercera  opcion ' );
             IF  Vnivel = 'MA' then  --todo lleva precio 
             
              --dbms_output.put_line('tercera  opcion  MA '   );
                  -- caso 2 segunda o mas compras con etiqueta  Soilo con costo 
              OPEN regist_opci_titulacion FOR
                 SELECT substr(ZSTPARA_PARAM_DESC,instr(ZSTPARA_PARAM_DESC,',',1)+1,10) mate, ZSTPARA_PARAM_DESC||' $ '||vcosto
                        FROM zstpara 
                        WHERE 1=1
                        AND ZSTPARA_MAPA_ID= 'ASE_TITULACION'
                        and ZSTPARA_PARAM_ID in (SELECT ZSTPARA_PARAM_ID
                                                    FROM zstpara 
                                                    WHERE 1=1
                                                     AND ZSTPARA_MAPA_ID= 'ASE_TITULACION'
                                                    AND ZSTPARA_PARAM_VALOR= 'CON COSTO')
                  UNION
                  SELECT substr(ZSTPARA_PARAM_DESC,instr(ZSTPARA_PARAM_DESC,',',1)+1,10) mate, ZSTPARA_PARAM_DESC||' $ '||vcosto
                        FROM zstpara 
                        WHERE 1=1
                        AND ZSTPARA_MAPA_ID= 'ASE_TITULACION'
                        and ZSTPARA_PARAM_ID in (SELECT ZSTPARA_PARAM_ID
                                                    FROM zstpara 
                                                    WHERE 1=1
                                                     AND ZSTPARA_MAPA_ID= 'ASE_TITULACION'
                                                    AND ZSTPARA_PARAM_VALOR= 'SIN COSTO');                                
                                                    
             
             else
              -- dbms_output.put_line('tercera  opcion si tiene etiqueta primer compra DO ' || vl_existe||'-'||v1er_compra||'-'||Vnivel   );
               --- este caso se presenta todo lo del para pero con costo todas las opciones ok
                OPEN regist_opci_titulacion FOR
                   SELECT  substr(ZSTPARA_PARAM_DESC, instr(ZSTPARA_PARAM_DESC,',',1  )+1,10 )  mate, ZSTPARA_PARAM_DESC||' $ '||vcosto
                     FROM zstpara 
                      WHERE 1=1
                        AND ZSTPARA_MAPA_ID= 'ASE_TITULA_DO'
                        and substr(ZSTPARA_PARAM_ID, instr(ZSTPARA_PARAM_ID,',',1  )+1,4 ) = vcampus
                        and ZSTPARA_PARAM_VALOR = 'CON COSTO' 
                   Union
                    SELECT  substr(ZSTPARA_PARAM_DESC, instr(ZSTPARA_PARAM_DESC,',',1  )+1,10 )  mate, ZSTPARA_PARAM_DESC||' $ '||vcosto
                     FROM zstpara 
                      WHERE 1=1
                        AND ZSTPARA_MAPA_ID= 'ASE_TITULA_DO'
                        and substr(ZSTPARA_PARAM_ID, instr(ZSTPARA_PARAM_ID,',',1  )+1,4 ) = vcampus
                        and ZSTPARA_PARAM_VALOR = 'SIN COSTO'
                        
                        ;
                 
             
             end if;
          
       end if; 
    
 
                                
      RETURN(regist_opci_titulacion);
         
    EXCEPTION WHEN OTHERS THEN
     
     -- dbms_output.put_line('ERROR gral de opc_titulacion '||sqlerrm  );
     RETURN(regist_opci_titulacion);
     
     
 END f_opci_titulacion;





end PKG_SERV_SIU;
/

DROP PUBLIC SYNONYM PKG_SERV_SIU;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SERV_SIU FOR BANINST1.PKG_SERV_SIU;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_SERV_SIU TO PUBLIC;
