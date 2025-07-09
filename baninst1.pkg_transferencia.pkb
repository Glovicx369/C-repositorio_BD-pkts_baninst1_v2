DROP PACKAGE BODY BANINST1.PKG_TRANSFERENCIA;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_TRANSFERENCIA
-------------------------------------------------------------------------------------
--Author:EMONTADI                                                                           --
--Date: 28-01-2016                                                                            --
--comments: Elaborado para impactar para los pagos no identificados    --
--                en el alumno correspondiente                                           --
 ------------------------------------------------------------------------------------
IS 

              
FUNCTION NO_IDENTIFICADOS(p_folio IN VARCHAR2, p_cuenta IN varchar2, p_sec IN NUMBER,  p_id_destino VARCHAR2, num_pago in varchar2, num_docto in varchar2, texto in varchar2, cod_det IN varchar2) --return varchar2 
RETURN PKG_TRANSFERENCIA.products_type
IS 
            v_pidm NUMBER(20);
            v_sec NUMBER:= p_sec;
            v_pidm_dest NUMBER(20);
            v_tran_cancela number;
            v_tran_transfiere number; 
            v_error varchar2(200);
            conta    number;
            longitud number;
            t1         varchar2(60);
            t2         varchar2(60);
            t3         varchar2(60);
            desc_detl varchar2(30);
            ptex3 varchar2(4000);
            v_error_transfer varchar2(4000):='EXITO';
            
          
cur pkg_transferencia.products_type;

BEGIN 
  

          v_error:=null;
          
           begin
           select spriden_pidm into v_pidm from spriden
           where spriden_id=p_cuenta
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
           exception when others then
           dbms_output.put_line('No existe estudiante/cuenta:'||p_cuenta );
           v_error:='No existe estudiante/cuenta:'||p_cuenta;
           open cur for select null, null, null, v_error from dual;
                    RETURN (cur);
                    -- return(v_error);
           end;
           
           begin
           select spriden_pidm into v_pidm_dest from spriden
           where spriden_id=p_id_destino
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
           exception when others then
            dbms_output.put_line('No existe estudiante/cuenta:'||p_cuenta );
           v_error:='No existe estudiante/cuenta:'||p_id_destino ;
           open cur for select null, null, null, v_error from dual;
                     RETURN (cur);
             --return (v_error);
           end;
          
           select count(*) 
            into conta from tbraccd
           where tbraccd_pidm=v_pidm
           and   tbraccd_tran_number=v_sec;
           
           if conta=0 then
            --dbms_output.put_line('No existe estudiante/cuenta/transacción:'||p_cuenta||' '||v_sec );
            --v_error:='No existe estudiante/cuenta/transacción:'||p_cuenta||' '||v_sec ;
             open cur for select null, null, null, 'No existe estudiante/cuenta/transacción:'||p_cuenta||' '||v_sec from dual;
             v_error :=  'No existe estudiante/cuenta/transacción:'||p_cuenta||' '||v_sec;
                    RETURN (cur);
               --return(v_error);
          end if;
           

--********CLONANDO EL REGISTRO CON TBRACCD_AMOUNT NEGATIUVO Y TBRACCD_BALANCE = 0 **************--
            SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
            into v_tran_cancela 
            FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm;
            
            begin
            SELECT  tbbdetc_desc into desc_detl
            from tbbdetc
            where cod_det=tbbdetc_detail_code;
            exception when others then
            dbms_output.put_line( 'No existe código detalle:');
             v_error:= 'No existe código detalle:';
           open cur for select null, null, null, v_error from dual;
                     RETURN (cur);
             --return(v_error );
           end;    
 
         Begin
         
            INSERT INTO TBRACCD
            (TBRACCD_PIDM
            ,TBRACCD_TRAN_NUMBER
            ,TBRACCD_TERM_CODE
            ,TBRACCD_DETAIL_CODE
            ,TBRACCD_USER
            ,TBRACCD_ENTRY_DATE
            ,TBRACCD_AMOUNT
            ,TBRACCD_BALANCE
            ,TBRACCD_EFFECTIVE_DATE
            ,TBRACCD_TRAN_NUMBER_PAID
            ,TBRACCD_DESC
            ,TBRACCD_CROSSREF_DETAIL_CODE
            ,TBRACCD_SRCE_CODE
            ,TBRACCD_ACCT_FEED_IND
            ,TBRACCD_ACTIVITY_DATE
            ,TBRACCD_SESSION_NUMBER
            ,TBRACCD_TRANS_DATE
            ,TBRACCD_PAYMENT_ID
            ,TBRACCD_DOCUMENT_NUMBER
            ,TBRACCD_CURR_CODE
            ,TBRACCD_DATA_ORIGIN
            ,TBRACCD_CREATE_SOURCE
            ,TBRACCD_SURROGATE_ID
            ,TBRACCD_VERSION
            ,TBRACCD_PERIOD
            ,TBRACCD_FOREIGN_AMOUNT
            )
            SELECT 
            TBRACCD_PIDM
            ,v_tran_cancela
            ,TBRACCD_TERM_CODE
            ,cod_det
            ,'POLIZAS'
            ,SYSDATE
            ,TBRACCD_AMOUNT     *-1
            ,TBRACCD_BALANCE * 0
            ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL POSTEO--
            ,v_sec
            ,desc_detl
            ,TBRACCD_CROSSREF_DETAIL_CODE
            ,TBRACCD_SRCE_CODE
            ,TBRACCD_ACCT_FEED_IND
            ,SYSDATE
            ,TBRACCD_SESSION_NUMBER
            ,TBRACCD_TRANS_DATE
            ,substr(num_pago,1,20)
            ,substr(num_docto,1,8)
            ,TBRACCD_CURR_CODE
            ,TBRACCD_DATA_ORIGIN
            ,TBRACCD_CREATE_SOURCE
            ,TBRACCD_SURROGATE_ID
            ,TBRACCD_VERSION
            ,p_folio
            ,1
            FROM TBRACCD
            WHERE TBRACCD_PIDM = v_pidm 
            AND TBRACCD_TRAN_NUMBER = p_sec;
         Exception when others then
            --dbms_output.put_line( 'No existe código detalle:');
            -- v_error:= 'No existe código detalle:';
            v_error := 'Error al insertar en Tbraccd bloque1'||v_error_transfer ||' := ' ||sqlerrm;
           open cur for select null, null, null,  v_error from dual;
                     RETURN (cur);
             --return(v_error );
         end;     
         
         Begin                  
            v_error_transfer:=pkg_simoba.sp_reference( v_pidm, v_tran_cancela, texto);
            If v_error_transfer !=  'EXITO' then 
               v_error := 'Error al Insertar Texto bloque1 '||v_error_transfer;
            End if;
            
         Exception when others then
            --dbms_output.put_line( 'No existe código detalle:');
            -- v_error:= 'No existe código detalle:';
            v_error := 'Error en Texto  bloque1'||v_error_transfer ||' := ' ||sqlerrm;
           open cur for select null, null, null,  v_error from dual;
                     RETURN (cur);
             --return(v_error );
         end;     
                                              
        Begin                                   
            update  tbraccd set tbraccd_balance=0
            where tbraccd_pidm=v_pidm
            and     tbraccd_tran_number=p_sec;
        Exception when others then
            --dbms_output.put_line( 'No existe código detalle:');
            -- v_error:= 'No existe código detalle:';
            v_error := 'Error al actualizar Tbraccd  bloque1' ||' := ' ||sqlerrm;
           open cur for select null, null, null,  v_error from dual;
                     RETURN (cur);
             --return(v_error );
         end;     
        
         
--********INSERTANDO EL REGISTRO AL PIDM DESTINO  CON TBRACCD_BALANCE = 0 **************--

         Begin
    
                SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                    into v_tran_transfiere 
                FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm_dest;


               INSERT INTO TBRACCD
                        (TBRACCD_PIDM
                        ,TBRACCD_TRAN_NUMBER
                        ,TBRACCD_TERM_CODE
                        ,TBRACCD_DETAIL_CODE
                        ,TBRACCD_USER
                        ,TBRACCD_ENTRY_DATE
                        ,TBRACCD_AMOUNT
                        ,TBRACCD_BALANCE
                        ,TBRACCD_EFFECTIVE_DATE
                        ,TBRACCD_DESC
                        ,TBRACCD_CROSSREF_DETAIL_CODE
                        ,TBRACCD_SRCE_CODE
                        ,TBRACCD_ACCT_FEED_IND
                        ,TBRACCD_ACTIVITY_DATE
                        ,TBRACCD_SESSION_NUMBER
                        ,TBRACCD_TRANS_DATE
                        ,TBRACCD_PAYMENT_ID
                        ,TBRACCD_DOCUMENT_NUMBER
                        ,TBRACCD_CURR_CODE
                        ,TBRACCD_DATA_ORIGIN
                        ,TBRACCD_CREATE_SOURCE
                        ,TBRACCD_SURROGATE_ID
                        ,TBRACCD_VERSION
                        ,TBRACCD_PERIOD
                        ,TBRACCD_FOREIGN_AMOUNT
                        )
                        SELECT 
                         v_pidm_dest 
                        ,v_tran_transfiere
                        ,TBRACCD_TERM_CODE
                        ,cod_det
                        ,'POLIZAS'
                        ,SYSDATE
                        ,TBRACCD_AMOUNT
                        ,TBRACCD_AMOUNT*-1
                        ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL POSTEO--
                        ,desc_detl
                        ,TBRACCD_CROSSREF_DETAIL_CODE
                        ,TBRACCD_SRCE_CODE
                        ,TBRACCD_ACCT_FEED_IND
                        ,SYSDATE
                        ,TBRACCD_SESSION_NUMBER
                        ,TBRACCD_TRANS_DATE
                        ,substr(num_pago,1,20)
                        ,substr(num_docto,1,8)
                        ,TBRACCD_CURR_CODE
                        ,TBRACCD_DATA_ORIGIN
                        ,TBRACCD_CREATE_SOURCE
                        ,TBRACCD_SURROGATE_ID
                        ,TBRACCD_VERSION
                        ,p_folio
                        ,2
                        FROM TBRACCD
                        WHERE TBRACCD_PIDM = v_pidm 
                        AND TBRACCD_TRAN_NUMBER = v_sec;
  
         Exception when others then
                v_error := 'Error al insertar en Tbraccd bloque2'||' := ' ||sqlerrm;
               open cur for select null, null, null,  v_error from dual;
                         RETURN (cur);
                 --return(v_error );
         End;    
                      
          Begin
                    v_error_transfer:= pkg_simoba.sp_reference( v_pidm_dest, v_tran_transfiere, texto);
                        If v_error_transfer !=  'EXITO' then 
                           v_error := 'Error al Insertar Texto bloque2 '||v_error_transfer;
                        End if;
                    
                    
          Exception when others then
             v_error := 'Error en el Texto bloque 2'||' := ' ||v_error_transfer;
            open cur for select null, null, null,  v_error from dual;
                 RETURN (cur);
          End;            
               
  
 
--***********************INSERTANDO  EN  LA  TABLA  BITACORA************************--
--dbms_output.put_line('p_folio:'||p_folio||'-'||'v_sec:'||v_sec||'-'||'v_tran_cancela:'||v_tran_cancela||'-'||'v_pidm_dest:'||v_pidm_dest||'-'||'v_tran_transfiere:'||v_tran_transfiere);

      Begin   

                INSERT INTO TBITANI
                (
                TBITANI_FOLIO
                ,TBITANI_TIPO_POLIZA
                ,TBITANI_PIDM_ORIGEN 
                ,TBITANI_MONTO_ORIGEN
                ,TBITANI_TRAN_NUMBER_ORIGEN
                ,TBITANI_TRAN_NUMBER_CANCELA
                ,TBITANI_FECHA_TRAN
                ,TBITANI_PIDM_DESTINO --(p_matricula)
                ,TBITANI_TRAN_NUMBER_DESTINO
                ,TBITANI_MONTO_DESINO
                ,TBITANI_ACTIVITY_DATE
                ,TBITANI_PROCESO_ID
                )
                SELECT
                p_folio,
                'TI',
                v_pidm --PIDM ORIGEN--
                ,TBRACCD_AMOUNT --MONTO ORIGEN--
                ,v_sec --TBRACCD_TRAN_NUMBER ORIGEN--
                ,v_tran_cancela -- Transacción que cancela
                ,TBRACCD_ENTRY_DATE -- FECHA DE TRANSACCION--
                ,v_pidm_dest --PIDM DESTINO--
                ,v_tran_transfiere
                ,TBRACCD_AMOUNT --MONTO DESTINO
                ,SYSDATE --FECHA DEL SISTEMA--
                ,(select nvl(max(tbitani_proceso_id),0)+1 from tbitani
                   where tbitani_folio=p_folio) --ID DEPROCESO (NO IDENTIFICADOS
                            FROM TBRACCD
                            WHERE TBRACCD_PIDM = v_pidm 
                            AND TBRACCD_TRAN_NUMBER = v_sec;
                -- dbms_output.put_line('inserta registro bitacora'); 

                COMMIT;
              
      Exception
      When others then 
            v_error := 'Error al insertar en Bitacora bloque2'||v_error_transfer ||' := ' ||sqlerrm;
            open cur for select null, null, null,  v_error from dual;
                     RETURN (cur);
      End;    

        If v_error is null then       
                v_error:='Proceso exitoso';
               open cur for select a.spriden_id, tbitani_tran_number_cancela, b.spriden_id, tbitani_tran_number_destino
                                   from tbitani, spriden a, spriden b
                                   where tbitani_pidm_origen=a.spriden_pidm
                                   and     tbitani_pidm_destino=b.spriden_pidm
                                   and     tbitani_folio=p_folio;

                RETURN (cur);
         Else
               open cur for select null, null, null,  v_error from dual;
                         RETURN (cur);
                 --return(v_error );
          End if;    
    
dbms_output.put_line(v_error);  
                 
EXCEPTION
    WHEN OTHERS THEN 
    v_error:='ERROR PKG_TRANSFERENCIA: ' || SQLERRM;
    dbms_output.put_line('ERROR:'||v_error||'*'||v_error_transfer);
    open cur for select null, null, null,v_error  from dual;
                    RETURN (cur);
  
END NO_IDENTIFICADOS;  

function  REASIGNACION (folio IN varchar2, id_origen IN VARCHAR2,  tran_origen in number,monto IN number,  id_destino IN varchar2, num_pago in varchar2, num_docto in varchar2, texto in varchar2, cod_det IN varchar2  )  
RETURN  PKG_TRANSFERENCIA.products_type  
  IS 

v_pidm number;
v_pidm_dest number;
conta    number;
v_tran_cancela number;
v_tran_diferencia number;
v_tran_transfiere number;
monto_origen decimal(16,2);
v_error    varchar2(200);
longitud number;
t1         varchar2(60);
t2         varchar2(60);
t3         varchar2(60);
desc_detl varchar2(30);
ptex3 varchar2(4000);
v_error_transfer varchar2(4000);

cur pkg_transferencia.products_type;

begin
           v_error := null;     

           begin
           select spriden_pidm into v_pidm 
           from spriden
           where spriden_id=id_origen
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
           exception when others then
           --dbms_output.put_line('No existe estudiante/cuenta:'||id_origen);
           v_error := 'No existe estudiante/cuenta:'||id_origen;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||id_origen from dual;
                     RETURN (cur);
           end;
           
           --dbms_output.put_line('v_pidm:'||v_pidm);
           begin
           select spriden_pidm into v_pidm_dest from spriden
           where spriden_id=id_destino
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
           exception when others then
           --dbms_output.put_line('No existe estudiante/cuenta:'||id_destino);
           v_error := 'No existe estudiante/cuenta:'||id_destino;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||id_destino from dual;
                     RETURN (cur);
           end;
           
           --dbms_output.put_line('v_pidm_dest:'||v_pidm_dest);
           select count(*) into conta from tbraccd
           where tbraccd_pidm=v_pidm
           and     tbraccd_tran_number=tran_origen;
           --dbms_output.put_line('conta_origen:'||conta);
          if conta=0 then
          v_error := 'No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen;
             open cur for select null, null, null, 'No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen from dual;
                    RETURN (cur);
          end if;
           
           select count(*) into conta from tbraccd, tbrappl
           where tbraccd_pidm=v_pidm
          and     tbraccd_tran_number=tran_origen
           and     tbrappl_pidm=tbraccd_pidm
           and     tbrappl_pay_tran_number=tbraccd_tran_number
           and     tbrappl_reappl_ind = 'Y';
           --dbms_output.put_line('conta_origen_reappl:'||conta);
           if conta=1 then
           v_error := 'Estudiante/cuenta/transacción NO puede reasignarse se encuentra Cancelada:'||id_origen||' '||tran_origen;
              open cur for select null, null, null, 'Estudiante/cuenta/transacción NO puede reasignarse se encuentra Cancelada:'||id_origen||' '||tran_origen from dual;
                     RETURN (cur);
           end if;
 
    Begin

            For pagoppl in (select TBRAPPL_PIDM, TBRAPPL_PAY_TRAN_NUMBER, TBRAPPL_CHG_TRAN_NUMBER, TBRAPPL_AMOUNT, TBRAPPL_DIRECT_PAY_TYPE
                                from tbrappl 
                                Where TBRAPPL_PIDM = v_pidm
                                And TBRAPPL_PAY_TRAN_NUMBER = tran_origen
                                And TBRAPPL_REAPPL_IND is null )  loop
                                                                        
                                gb_common.p_set_context('TB_RECEIVABLE','PROCESS','APPLPMNT-FORCE','N');

                               tv_application.p_unapply_by_tran_number( p_pidm               => pagoppl.TBRAPPL_PIDM,
                                                                                              p_pay_tran_number    => pagoppl.TBRAPPL_PAY_TRAN_NUMBER,
                                                                                              p_unapply_direct_pay => pagoppl.TBRAPPL_DIRECT_PAY_TYPE);   
                                                                                                                                      
                                                                       
                               --dbms_output.put_line('pidm:' ||pagoppl.TBRAPPL_PIDM||'pay_tran:'|| pagoppl.TBRAPPL_PAY_TRAN_NUMBER||' '||'chg_tran:'||  pagoppl.TBRAPPL_CHG_TRAN_NUMBER);                                              
                                                                        
            End Loop pagoppl;
                                                         
             --********CLONANDO EL REGISTRO CON TBRACCD_AMOUNT NEGATIVO Y TBRACCD_BALANCE = 0 **************--
                SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                    into v_tran_cancela 
                 FROM TBRACCD 
                 WHERE TBRACCD_PIDM = v_pidm;
                 
               Begin
                SELECT  tbbdetc_desc into desc_detl
                from tbbdetc
                where cod_det=tbbdetc_detail_code;
               Exception when others then
                --dbms_output.put_line( 'No existe código detalle:');
                v_error:= 'No existe código detalle:';
               open cur for select null, null, null, 'No existe código detalle:' from dual;
                         RETURN (cur);
               end;    
                  
               Begin                      
                                       
                        INSERT INTO TBRACCD
                        (TBRACCD_PIDM
                        ,TBRACCD_TRAN_NUMBER
                        ,TBRACCD_TERM_CODE
                        ,TBRACCD_DETAIL_CODE
                        ,TBRACCD_USER
                        ,TBRACCD_ENTRY_DATE
                        ,TBRACCD_AMOUNT
                        ,TBRACCD_BALANCE
                        ,TBRACCD_EFFECTIVE_DATE
                        ,TBRACCD_TRANS_DATE
                        ,TBRACCD_TRAN_NUMBER_PAID
                        ,TBRACCD_DESC
                        ,TBRACCD_CROSSREF_DETAIL_CODE
                        ,TBRACCD_SRCE_CODE
                        ,TBRACCD_ACCT_FEED_IND
                        ,TBRACCD_ACTIVITY_DATE
                        ,TBRACCD_SESSION_NUMBER
                        ,TBRACCD_PAYMENT_ID
                        ,TBRACCD_DOCUMENT_NUMBER
                        ,TBRACCD_CURR_CODE
                        ,TBRACCD_DATA_ORIGIN
                        ,TBRACCD_CREATE_SOURCE
                        ,TBRACCD_PERIOD
                        ,TBRACCD_FOREIGN_AMOUNT
                        )
                        SELECT 
                        TBRACCD_PIDM
                        ,v_tran_cancela
                        ,TBRACCD_TERM_CODE
                        ,cod_det
                        ,'POLIZAS'
                        ,SYSDATE
                        ,TBRACCD_AMOUNT   *-1
                        ,0
                        ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL POSTEO--
                        ,TBRACCD_TRANS_DATE
                        ,tran_origen
                        ,desc_detl
                        ,TBRACCD_CROSSREF_DETAIL_CODE
                        ,TBRACCD_SRCE_CODE
                        ,TBRACCD_ACCT_FEED_IND
                        ,SYSDATE
                        ,0
                        ,substr(num_pago,1,20)
                        ,substr(num_docto,1,8)
                        ,TBRACCD_CURR_CODE
                        ,TBRACCD_DATA_ORIGIN
                        ,TBRACCD_CREATE_SOURCE
                        ,folio
                        ,1
                        FROM TBRACCD
                        WHERE TBRACCD_PIDM =  v_pidm 
                        AND TBRACCD_TRAN_NUMBER =tran_origen;-- '30535'
               Exception
                  When others then 
                        v_error := 'Error al insertar en Tbraccd bloque3:= '||v_error_transfer ||' := ' ||sqlerrm;
                        open cur for select null, null, null,  v_error from dual;
                                 RETURN (cur);
               End;    

               Begin
                v_error_transfer:= pkg_simoba.sp_reference( v_pidm, v_tran_cancela, texto);
                        If v_error_transfer !=  'EXITO' then 
                           v_error := 'Error al Insertar Texto bloque3 '||v_error_transfer;
                        End if;
                
               Exception
                  When others then 
                        v_error := 'Error al insertar Texto bloque3:= '||v_error_transfer ||' := ' ||sqlerrm;
                        open cur for select null, null, null,  v_error from dual;
                                 RETURN (cur);
               End;    

               Begin
                     update  tbraccd set tbraccd_balance=0
                     where tbraccd_pidm=v_pidm
                     and     tbraccd_tran_number=tran_origen;
               Exception
                  When others then 
                        v_error := 'Error al Actualizar Tbraccd bloque3:= '||sqlerrm;
                        open cur for select null, null, null,  v_error from dual;
                                 RETURN (cur);
               End;
                
               Begin                                                                                                                             
                             Update TVRACCD
                             set TVRACCD_BALANCE = 0
                             Where TVRACCD_PIDM = v_pidm
                             And TVRACCD_ACCD_TRAN_NUMBER = tran_origen;                                                            
               Exception
                  When others then 
                        v_error := 'Error al Actualizar Tvraccd bloque3:= '||sqlerrm;
                        open cur for select null, null, null,  v_error from dual;
                                 RETURN (cur);
               End;
                 
                            --********REALIZANDO LA TRANSFERENCIA**************--
                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 into v_tran_transfiere FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm_dest;
                        
               Begin         
                           INSERT INTO TBRACCD
                                    (TBRACCD_PIDM
                                    ,TBRACCD_TRAN_NUMBER
                                    ,TBRACCD_TERM_CODE
                                    ,TBRACCD_DETAIL_CODE
                                    ,TBRACCD_USER
                                    ,TBRACCD_ENTRY_DATE
                                    ,TBRACCD_AMOUNT
                                    ,TBRACCD_BALANCE
                                    ,TBRACCD_EFFECTIVE_DATE
                                    ,TBRACCD_DESC
                                    ,TBRACCD_CROSSREF_DETAIL_CODE
                                    ,TBRACCD_SRCE_CODE
                                    ,TBRACCD_ACCT_FEED_IND
                                    ,TBRACCD_ACTIVITY_DATE
                                    ,TBRACCD_SESSION_NUMBER
                                    ,TBRACCD_TRANS_DATE
                                    ,TBRACCD_PAYMENT_ID
                                    ,TBRACCD_DOCUMENT_NUMBER
                                    ,TBRACCD_CURR_CODE
                                    ,TBRACCD_DATA_ORIGIN
                                    ,TBRACCD_CREATE_SOURCE
                                    ,TBRACCD_SURROGATE_ID
                                    ,TBRACCD_VERSION
                                    ,TBRACCD_PERIOD
                                    ,TBRACCD_FOREIGN_AMOUNT
                                    )
                                    SELECT 
                                     v_pidm_dest 
                                    ,v_tran_transfiere
                                    ,TBRACCD_TERM_CODE
                                    ,cod_det
                                    ,'POLIZAS'
                                    ,SYSDATE
                                    ,TBRACCD_AMOUNT
                                    ,TBRACCD_AMOUNT *-1
                                    ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL POSTEO--
                                    ,desc_detl
                                    ,TBRACCD_CROSSREF_DETAIL_CODE
                                    ,TBRACCD_SRCE_CODE
                                    ,TBRACCD_ACCT_FEED_IND
                                    ,SYSDATE
                                    ,TBRACCD_SESSION_NUMBER
                                    ,TBRACCD_TRANS_DATE
                                    ,substr(num_pago,1,20)
                                    ,substr(num_docto,1,8)
                                    ,TBRACCD_CURR_CODE
                                    ,TBRACCD_DATA_ORIGIN
                                    ,TBRACCD_CREATE_SOURCE
                                    ,TBRACCD_SURROGATE_ID
                                    ,TBRACCD_VERSION
                                    ,folio
                                    ,2
                                    FROM TBRACCD
                                    WHERE TBRACCD_PIDM = v_pidm 
                                    AND TBRACCD_TRAN_NUMBER = tran_origen;

               Exception
                  When others then 
                        v_error := 'Error al Insertar Tbraccd bloque3.1:= '||sqlerrm;
                        open cur for select null, null, null,  v_error from dual;
                                 RETURN (cur);
               End;
                                    
               Begin
                        v_error_transfer:=pkg_simoba.sp_reference( v_pidm_dest, v_tran_transfiere, texto);
                        If v_error_transfer !=  'EXITO' then 
                           v_error := 'Error al Insertar Texto bloque3.1 '||v_error_transfer;
                        End if;

                        If v_error_transfer !=  'EXITO' then 
                           v_error := 'Error al Insertar Texto bloque3.1 '||v_error_transfer;
                        End if;
                           
               Exception
                  When others then 
                        v_error := 'Error al Insertar Texto bloque3.1:= '||sqlerrm;
                        open cur for select null, null, null,  v_error from dual;
                                 RETURN (cur);
               End;
                        
                                    
               
               Begin                                                        

                        --***********************INSERTANDO  EN  LA  TABLA  BITACORA************************--
                        INSERT INTO TBITANI
                        (
                        TBITANI_FOLIO
                        ,TBITANI_TIPO_POLIZA
                        ,TBITANI_PIDM_ORIGEN 
                        ,TBITANI_MONTO_ORIGEN
                        ,TBITANI_TRAN_NUMBER_ORIGEN
                        ,TBITANI_TRAN_NUMBER_CANCELA
                        ,TBITANI_FECHA_TRAN
                        ,TBITANI_PIDM_DESTINO --(p_matricula)
                        ,TBITANI_TRAN_NUMBER_DESTINO
                        ,TBITANI_MONTO_DESINO
                        ,TBITANI_ACTIVITY_DATE
                        ,TBITANI_PROCESO_ID
                        )
                        SELECT
                        folio,
                        'TR',
                        v_pidm --PIDM ORIGEN--
                        ,monto --MONTO ORIGEN--
                        ,tran_origen --TBRACCD_TRAN_NUMBER ORIGEN--
                        ,v_tran_cancela -- Transacción que cancela
                        ,TBRACCD_ENTRY_DATE -- FECHA DE TRANSACCION--
                        ,v_pidm_dest --PIDM DESTINO--
                        ,v_tran_transfiere
                        ,monto --MONTO DESTINO
                        ,SYSDATE --FECHA DEL SISTEMA--
                        ,(select nvl(max(tbitani_proceso_id),0)+1 from tbitani
                           where tbitani_folio=folio) --ID DEPROCESO (NO IDENTIFICADOS
                                    FROM TBRACCD
                                    WHERE TBRACCD_PIDM = v_pidm 
                                    AND TBRACCD_TRAN_NUMBER = tran_origen;

                        COMMIT;
                        
               Exception
                  When others then 
                        v_error := 'Error al Insertar la Bitacora bloque3.1:= '||sqlerrm;
                        open cur for select null, null, null,  v_error from dual;
                                 RETURN (cur);
               End;
       
    
              If v_error is null then       
                                   v_error:='Proceso exitoso';
                                   open cur for select a.spriden_id, tbitani_tran_number_cancela, b.spriden_id, tbitani_tran_number_destino
                                                       from tbitani, spriden a, spriden b
                                                       where tbitani_pidm_origen=a.spriden_pidm
                                                       and     tbitani_pidm_destino=b.spriden_pidm
                                                       and     tbitani_folio=folio;
                                    RETURN (cur);           
             Else
                   open cur for select null, null, null,  v_error from dual;
                             RETURN (cur);
                     --return(v_error );
              End if;    

    
    
    

    Exception
    When Others then 
    v_error:='ERROR PKG_TRANSFERENCIA: ' || SQLERRM;
    open cur for select null, null, null,v_error  from dual;
                    RETURN (cur);
    End;

End REASIGNACION;   

function  REASIGNACION_DIV (folio IN varchar2, id_origen IN VARCHAR2,  tran_origen in number,monto IN number,  num_pago in varchar2, num_docto in varchar2, texto in varchar2 , cod_det IN varchar2,
                                             id_destino1 IN varchar2, monto1 varchar2)  RETURN  PKG_TRANSFERENCIA.products_type
  IS 

v_pidm number;
v_pidm_dest number;
v_pidm_dest1 number;
v_pidm_dest2 number;
v_pidm_dest3 number;
v_pidm_dest4 number;
v_pidm_dest5 number;
v_pidm_dest6 number;
v_pidm_dest7 number;
v_pidm_dest8 number;
v_pidm_dest9 number;
v_pidm_dest10 number;
v_id_destino     varchar2(9);
conta    number;
v_tran_cancela number;
v_tran_diferencia number;
v_tran_transfiere number;
monto_origen decimal(16,2);
v_error    varchar2(2000);
v_pidms   varchar2(120);
i              number;
importe    number;
t1         varchar2(60);
t2         varchar2(60);
t3         varchar2(60);
desc_detl varchar2(30);
longitud number;
aux       varchar2(1);
inicio     number;
iden1      varchar2(10);
iden2      varchar2(10);
ptex3 varchar2(4000);
v_error_transfer varchar2(4000);


cur pkg_transferencia.products_type;

begin
 
               
          v_error :=null;          

          begin
               select spriden_pidm into v_pidm 
               from spriden
               where spriden_id=id_origen
               and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
          Exception when others then
--           dbms_output.put_line('No existe estudiante/cuenta origen:'||id_origen);
           v_error :=  'No existe estudiante/cuenta:'||id_origen;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||id_origen from dual;
                     RETURN (cur);
          End;
          
            
        delete from zbitani;
        commit;

        longitud:=length(id_destino1);
        inicio:=1;
        conta:=0;



        For x in 1 .. longitud loop
             aux:=substr(id_destino1,x,1);
                if aux=',' or aux='|' then
                   iden1:=substr(id_destino1,inicio,x-inicio);
                   inicio:=x+1;
                   conta:=conta+1;
                    Begin
                           insert into zbitani values(conta, iden1, null);
                    Exception when others then
                         v_error:= 'Se presento un Error al insertar zbitani :' ||sqlerrm;
                        Open cur for select null, null, null, v_error from dual;
                        RETURN (cur);
                    End;                   
         --          dbms_output.put_line('cuenta:'||iden1);
                end if;
        End loop;
        commit;
        
        longitud:=length(monto1);
        inicio:=1;
        conta:=0;

    
            for x in 1 .. longitud loop
                aux:=substr(monto1,x,1);
                        if aux=',' or aux='|' then
                           iden2:=substr(monto1,inicio,x-inicio);
                           inicio:=x+1;
                           conta:=conta+1;
                           Begin
                                   update zbitani set importe=iden2
                                   where numero=conta;
                           Exception when others then
                               v_error:= 'Se presento un Error al actualizar zbitani :'||sqlerrm;
                                Open cur for select null, null, null, v_error from dual;
                                RETURN (cur);
                            End;
                           
                           --dbms_output.put_line('conta-importe:'||conta||' '||iden2);
                        end if;
            end loop;
            commit;
     



           v_pidms:=null;
           for xx in (select iden from zbitani order by numero) loop
               begin
                   select spriden_pidm into v_pidm_dest from spriden
                   where spriden_id=xx.iden
                   and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);       
               exception when others then
               v_pidms:=v_pidms||' '||xx.iden;
               end;
           end loop;
           
           if v_pidms is not null then
            --dbms_output.put_line('No existe estudiante(s)/cuenta(s)a transferir:'||v_pidms);
            v_error:=  'No existe estudiante/cuenta:'||v_pidms;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||v_pidms from dual;
                     RETURN (cur);
            end if;
          
          -- dbms_output.put_line('v_pidms_dest:'||v_pidm_dest1||' '||v_pidm_dest2||' '||v_pidm_dest3||' '||v_pidm_dest4||' '||v_pidm_dest5||' '||v_pidm_dest6||' '||v_pidm_dest7||' '||v_pidm_dest8||' '||v_pidm_dest9||' '||v_pidm_dest10);
           select count(*) 
                into conta from tbraccd
           where tbraccd_pidm=v_pidm
           and     tbraccd_tran_number=tran_origen;
           
      --     dbms_output.put_line('conta_origen:'||conta);
      
          if conta=0 then
             v_error:= 'No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen;
             open cur for select null, null, null, 'No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen from dual;
                    RETURN (cur);
          end if;
           
           select count(*) into conta 
           from tbraccd, tbrappl
           where tbraccd_pidm=v_pidm
          and     tbraccd_tran_number=tran_origen
           and     tbrappl_pidm=tbraccd_pidm
           and     tbrappl_pay_tran_number=tbraccd_tran_number
           and     tbrappl_reappl_ind = 'Y';
           
         --  dbms_output.put_line('conta_origen_reappl:'||conta);
           if conta=1 then
             v_error := 'Estudiante/cuenta/transacción NO puede reasignarse se encuentra Cancelada:'||id_origen||' '||tran_origen;
              open cur for select null, null, null, 'Estudiante/cuenta/transacción NO puede reasignarse se encuentra Cancelada:'||id_origen||' '||tran_origen from dual;
                     RETURN (cur);
           end if;
 
    Begin
                            --dbms_output.put_line('Empezamos pidm:' ||v_pidm||'pay_tran:'|| tran_origen);

            For pagoppl in (select TBRAPPL_PIDM, TBRAPPL_PAY_TRAN_NUMBER, TBRAPPL_CHG_TRAN_NUMBER, TBRAPPL_AMOUNT, TBRAPPL_DIRECT_PAY_TYPE
                                from tbrappl 
                                Where TBRAPPL_PIDM =v_pidm
                                And TBRAPPL_PAY_TRAN_NUMBER =tran_origen
                                And TBRAPPL_REAPPL_IND is null )  loop
                               -- dbms_output.put_line('Iniciamos');
                                gb_common.p_set_context('TB_RECEIVABLE','PROCESS','APPLPMNT-FORCE','N');

                               tv_application.p_unapply_by_tran_number( p_pidm               => pagoppl.TBRAPPL_PIDM,
                                                                                              p_pay_tran_number    => pagoppl.TBRAPPL_PAY_TRAN_NUMBER,
                                                                                              p_unapply_direct_pay => pagoppl.TBRAPPL_DIRECT_PAY_TYPE);   

                              -- dbms_output.put_line('pidm:' ||pagoppl.TBRAPPL_PIDM||'pay_tran:'|| pagoppl.TBRAPPL_PAY_TRAN_NUMBER||' '||'chg_tran:'||  pagoppl.TBRAPPL_CHG_TRAN_NUMBER);                                              
                                                                        
            End Loop pagoppl;
            commit;
              
            Begin                
                     select tbraccd_amount into monto_origen from tbraccd
                     where tbraccd_pidm=v_pidm
                     and     tbraccd_tran_number=tran_origen;
            Exception when others then
            v_error := 'Se presento un Error al recuperar el monto bloque 4 :'||sqlerrm;
                Open cur for select null, null, null, v_error from dual;
             RETURN (cur);
            End;
  
            if monto_origen > monto then 
                            
                            SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                                into v_tran_diferencia 
                            FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm;
                                        
                            begin
                                    INSERT INTO TBRACCD
                                    (TBRACCD_PIDM
                                    ,TBRACCD_TRAN_NUMBER
                                    ,TBRACCD_TERM_CODE
                                    ,TBRACCD_DETAIL_CODE
                                    ,TBRACCD_USER
                                    ,TBRACCD_ENTRY_DATE
                                    ,TBRACCD_AMOUNT
                                    ,TBRACCD_BALANCE
                                    ,TBRACCD_EFFECTIVE_DATE
                                    ,TBRACCD_TRAN_NUMBER_PAID
                                    ,TBRACCD_DESC
                                    ,TBRACCD_CROSSREF_DETAIL_CODE
                                    ,TBRACCD_SRCE_CODE
                                    ,TBRACCD_ACCT_FEED_IND
                                    ,TBRACCD_ACTIVITY_DATE
                                    ,TBRACCD_SESSION_NUMBER
                                    ,TBRACCD_CURR_CODE
                                    ,TBRACCD_DATA_ORIGIN
                                    ,TBRACCD_CREATE_SOURCE
                                    ,TBRACCD_SURROGATE_ID
                                    ,TBRACCD_VERSION
                                    ,TBRACCD_PERIOD
                                    ,TBRACCD_TRANS_DATE
                                    ,TBRACCD_DOCUMENT_NUMBER
                                    )
                                    SELECT 
                                    TBRACCD_PIDM
                                    , v_tran_diferencia
                                    ,TBRACCD_TERM_CODE
                                    ,TBRACCD_DETAIL_CODE
                                    ,'POLIZAS'
                                    ,sysdate
                                    ,monto_origen - monto
                                    ,(monto_origen - monto)*-1
                                    ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL POSTEO--
                                    ,null
                                    ,TBRACCD_DESC
                                    ,TBRACCD_CROSSREF_DETAIL_CODE
                                    ,TBRACCD_SRCE_CODE
                                    ,TBRACCD_ACCT_FEED_IND
                                    ,SYSDATE
                                    ,0
                                    ,TBRACCD_CURR_CODE
                                    ,TBRACCD_DATA_ORIGIN
                                    ,TBRACCD_CREATE_SOURCE
                                    ,TBRACCD_SURROGATE_ID
                                    ,TBRACCD_VERSION
                                    ,folio
                                    ,TBRACCD_TRANS_DATE
                                    ,TBRACCD_DOCUMENT_NUMBER
                                    FROM TBRACCD
                                    WHERE TBRACCD_PIDM = v_pidm 
                                    AND TBRACCD_TRAN_NUMBER = tran_origen;
                            --commit;
                            Exception when others then
                             v_error := 'Error al insertar en Tbraccd bloque4'||' := ' ||sqlerrm;
                                Open cur for select null, null, null, v_error from dual;
                                RETURN (cur);
                            End;
 
                            --dbms_output.put_line('Inserta pago por la diferencia ....');
                             Begin
                                    v_error_transfer :=pkg_simoba.sp_reference( v_pidm, v_tran_diferencia, texto);

                                      If v_error_transfer !=  'EXITO' then 
                                           v_error := 'Se presento un Error en Texto bloque 4 '||v_error_transfer;
                                      End if;

                             Exception when others then
                                   Open cur for select null, null, null, 'Se presento un Error en Texto bloque 4 :'||v_error_transfer from dual;
                                    RETURN (cur);
                             End;
 
             End if;
                                                           
         --********CLONANDO EL REGISTRO CON TBRACCD_AMOUNT NEGATIVO Y TBRACCD_BALANCE = 0 **************--
            begin
                    SELECT  tbbdetc_desc into desc_detl
                    from tbbdetc
                    where cod_det=tbbdetc_detail_code;
                    exception when others then
            --dbms_output.put_line( 'No existe código detalle:');
            v_error := 'No existe código detalle bloque4:';
           open cur for select null, null, null, 'No existe código detalle bloque4:' from dual;
                     RETURN (cur);
           end;    
                                       
            SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                into v_tran_cancela 
            FROM TBRACCD 
            WHERE TBRACCD_PIDM = v_pidm;
                       
            Begin                  
                                        INSERT INTO TBRACCD
                                        (TBRACCD_PIDM
                                        ,TBRACCD_TRAN_NUMBER
                                        ,TBRACCD_TERM_CODE
                                        ,TBRACCD_DETAIL_CODE
                                        ,TBRACCD_USER
                                        ,TBRACCD_ENTRY_DATE
                                        ,TBRACCD_AMOUNT
                                        ,TBRACCD_BALANCE
                                        ,TBRACCD_EFFECTIVE_DATE
                                        ,TBRACCD_TRAN_NUMBER_PAID
                                        ,TBRACCD_DESC
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,TBRACCD_PAYMENT_ID
                                        ,TBRACCD_DOCUMENT_NUMBER
                                        ,TBRACCD_ACTIVITY_DATE
                                        ,TBRACCD_SESSION_NUMBER
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,TBRACCD_PERIOD
                                        ,TBRACCD_TRANS_DATE
                                        ,TBRACCD_FOREIGN_AMOUNT
                                        )
                                        SELECT 
                                        TBRACCD_PIDM
                                        ,v_tran_cancela
                                        ,TBRACCD_TERM_CODE
                                        ,cod_det
                                        ,'POLIZAS'
                                        ,sysdate
                                        ,TBRACCD_AMOUNT   *-1
                                        ,0
                                        ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL PAGO TRANSACCION--
                                        ,tran_origen
                                        ,desc_detl
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,num_pago
                                        ,num_docto
                                        ,SYSDATE
                                        ,0
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,folio
                                        ,TBRACCD_TRANS_DATE
                                        ,1
                                        FROM TBRACCD
                                        WHERE TBRACCD_PIDM =  v_pidm 
                                        AND TBRACCD_TRAN_NUMBER =tran_origen;-- '30535'
                                        
            Exception when others then
                 v_error := 'Error al insertar en Tbraccd bloque4.1'||' := ' ||sqlerrm;
                    Open cur for select null, null, null, v_error from dual;
                    RETURN (cur);
            End;                                        

            Begin           
                     
                 v_error_transfer:=pkg_simoba.sp_reference( v_pidm, v_tran_cancela, texto);

                If v_error_transfer !=  'EXITO' then 
                   v_error := 'Error al Insertar Texto bloque3.1 '||v_error_transfer;
                End if;
                                        
            Exception when others then
                    Open cur for select null, null, null, 'Error al insertar texto 4.1 '||v_error_transfer from dual;
                    RETURN (cur);
            End;                                        

            Begin                            
                 update  tbraccd set tbraccd_balance=0
                 where tbraccd_pidm=v_pidm
                 and     tbraccd_tran_number=tran_origen;
                             
            Exception when others then
                 v_error := 'Error al actualizar en Tbraccd bloque4.1'||' := ' ||sqlerrm;
                    Open cur for select null, null, null, v_error from dual;
                    RETURN (cur);
            End;                                        

             Begin                 
                     Update TVRACCD
                     set TVRACCD_BALANCE = 0
                     Where TVRACCD_PIDM = v_pidm
                     And TVRACCD_ACCD_TRAN_NUMBER = tran_origen;                                                            
                        commit;  
             Exception when others then
                     v_error := 'Error al actualizar en TVRACCD bloque4.1'||' := ' ||sqlerrm;
                        Open cur for select null, null, null, v_error from dual;
                        RETURN (cur);
             End;                                        
                                                                 

               for xx in (select spriden_pidm pidm, importe 
               from zbitani, spriden 
               where iden=spriden_id and spriden_change_ind is null
               order by numero) loop

                  if xx.pidm is not null then     
                    -- dbms_output.put_line('pidm - importe:'||xx.pidm||' '||xx.importe);
                            --********REALIZANDO LA TRANSFERENCIA**************--
                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                            into v_tran_transfiere 
                        FROM TBRACCD 
                        WHERE TBRACCD_PIDM = xx.pidm;
                        
                        Begin
                               INSERT INTO TBRACCD
                                        (TBRACCD_PIDM
                                        ,TBRACCD_TRAN_NUMBER
                                        ,TBRACCD_TERM_CODE
                                        ,TBRACCD_DETAIL_CODE
                                        ,TBRACCD_USER
                                        ,TBRACCD_ENTRY_DATE
                                        ,TBRACCD_AMOUNT
                                        ,TBRACCD_BALANCE
                                        ,TBRACCD_EFFECTIVE_DATE
                                        ,TBRACCD_DESC
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,TBRACCD_ACTIVITY_DATE
                                        ,TBRACCD_SESSION_NUMBER
                                        ,TBRACCD_TRANS_DATE
                                        ,TBRACCD_PAYMENT_ID
                                        ,TBRACCD_DOCUMENT_NUMBER
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,TBRACCD_SURROGATE_ID
                                        ,TBRACCD_VERSION
                                        ,TBRACCD_PERIOD
                                        ,TBRACCD_FOREIGN_AMOUNT
                                        )
                                        SELECT 
                                         xx.pidm 
                                        ,v_tran_transfiere
                                        ,TBRACCD_TERM_CODE
                                        ,cod_det
                                        ,'POLIZAS'
                                        ,sysdate
                                        ,xx.importe
                                        ,xx.importe*-1
                                        ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL PAGO TRANSACCION--
                                        ,desc_detl
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,SYSDATE
                                        ,TBRACCD_SESSION_NUMBER
                                        ,TBRACCD_TRANS_DATE
                                        ,num_pago
                                        ,num_docto
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,TBRACCD_SURROGATE_ID
                                        ,TBRACCD_VERSION
                                        ,folio
                                        ,2
                                        FROM TBRACCD
                                        WHERE TBRACCD_PIDM = v_pidm 
                                        AND TBRACCD_TRAN_NUMBER = tran_origen;--'30535'         
                                        
                        Exception when others then
                                 v_error := 'Error al insertar en TBRACCD bloque4.2'||' := ' ||sqlerrm;
                                    Open cur for select null, null, null, v_error from dual;
                                    RETURN (cur);
                        End;
                                                                  

                        Begin
                                v_error_transfer:= pkg_simoba.sp_reference( xx.pidm, v_tran_transfiere, texto);
                        Exception when others then
                                 v_error := 'Error al insertar en TBRACCD bloque4.2'||' := ' ||v_error_transfer;
                                    Open cur for select null, null, null, v_error from dual;
                                    RETURN (cur);
                        End;
                                 

                        --***********************INSERTANDO  EN  LA  TABLA  BITACORA************************--
                       Begin
                       
                                INSERT INTO TBITANI
                                (
                                TBITANI_FOLIO
                                ,TBITANI_TIPO_POLIZA
                                ,TBITANI_PIDM_ORIGEN 
                                ,TBITANI_MONTO_ORIGEN
                                ,TBITANI_TRAN_NUMBER_ORIGEN
                                ,TBITANI_TRAN_NUMBER_CANCELA
                                ,TBITANI_FECHA_TRAN
                                ,TBITANI_PIDM_DESTINO --(p_matricula)
                                ,TBITANI_TRAN_NUMBER_DESTINO
                                ,TBITANI_MONTO_DESINO
                                ,TBITANI_ACTIVITY_DATE
                                ,TBITANI_PROCESO_ID
                                )
                                SELECT
                                folio,
                                'TD',
                                v_pidm --PIDM ORIGEN--
                                ,monto --MONTO ORIGEN--
                                ,tran_origen --TBRACCD_TRAN_NUMBER ORIGEN--
                                ,v_tran_cancela -- Transacción que cancela
                                ,TBRACCD_ENTRY_DATE -- FECHA DE TRANSACCION--
                                ,xx.pidm --PIDM DESTINO--
                                ,v_tran_transfiere
                                ,xx.importe --MONTO DESTINO
                                ,SYSDATE --FECHA DEL SISTEMA--
                                ,(select nvl(max(tbitani_proceso_id),0)+1 from tbitani
                                   where tbitani_folio=folio) --ID DEPROCESO (NO IDENTIFICADOS
                                            FROM TBRACCD
                                            WHERE TBRACCD_PIDM = v_pidm 
                                            AND TBRACCD_TRAN_NUMBER = tran_origen;
                                            
                       Exception when others then
                                 v_error := 'Error al insertar en TBITANI bloque4.2'||' := ' ||sqlerrm;
                                    Open cur for select null, null, null, v_error from dual;
                                    RETURN (cur);
                        End;
                                            

                         commit;
                  end if;
              end loop

             COMMIT;
            -- dbms_output.put_line('se guardan transacciones');                       
              If v_error is null then       
                                   v_error:='Proceso exitoso';
                                   open cur for select a.spriden_id, tbitani_tran_number_cancela, b.spriden_id, tbitani_tran_number_destino
                                                       from tbitani, spriden a, spriden b
                                                       where tbitani_pidm_origen=a.spriden_pidm
                                                       and     tbitani_pidm_destino=b.spriden_pidm
                                                       and     tbitani_folio=folio;
                                    RETURN (cur);           
             Else
                   open cur for select null, null, null,  v_error from dual;
                             RETURN (cur);
                     --return(v_error );
              End if;    
                                                                                                                       
       

    Exception
    When Others then 
    v_error:='ERROR PKG_TRANSFERENCIA: ' || SQLERRM;
    dbms_output.put_line('v_error:'||v_error);
    open cur for select null, null, null,v_error  from dual;
                    RETURN (cur);
    End;

End REASIGNACION_DIV;   

function  REASIG_INTERCOM (folio IN varchar2, id_origen IN VARCHAR2,  tran_origen in number,cta_x_pagar IN varchar2,  id_destino IN varchar2, cta_x_cobrar IN varchar2, num_pago in varchar2, num_docto in varchar2, texto in varchar2,
                                            cod_det1 IN varchar2, cod_det2 IN varchar2 )  
RETURN  PKG_TRANSFERENCIA.products_type  
  IS 

v_pidm number;
v_pidm_cta number;
v_pidm_dest number;
v_pidm_dest_cta number;
conta    number;
v_tran_cancela number;
v_tran_diferencia number;
v_tran_transfiere number;
v_tran_x_cobrar  number;
v_tran_x_pagar   number;
monto_origen decimal(16,2);
v_error    varchar2(2000);
longitud number;
t1         varchar2(60);
t2         varchar2(60);
t3         varchar2(60);
desc_detl1 varchar2(30);
desc_detl2 varchar2(30);
periodo   varchar2(6);
f_tran      varchar2(10);
ptex3 varchar2(4000);
v_error_transfer  varchar2(4000);

cur pkg_transferencia.products_type;
begin
 
                
        v_error := null;

          begin
           select spriden_pidm into v_pidm 
           from spriden
           where spriden_id=id_origen
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
          exception when others then
          -- dbms_output.put_line('No existe estudiante/cuenta:'||id_origen);
          v_error := 'No existe estudiante/cuenta:'||id_origen;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||id_origen from dual;
                     RETURN (cur);
          end;
          
          -- dbms_output.put_line('v_pidm:'||v_pidm);
           begin
               select spriden_pidm into v_pidm_cta 
               from spriden
               where spriden_id=cta_x_pagar
               and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
           exception when others then
           --dbms_output.put_line('No existe estudiante/cuenta:'||cta_x_pagar);
           v_error :=  'No existe estudiante/cuenta:'||cta_x_pagar;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||cta_x_pagar from dual;
                     RETURN (cur);
           end;
           
           
           dbms_output.put_line('v_pidm_cta:'||v_pidm_cta);
           begin
           select spriden_pidm into v_pidm_dest from spriden
           where spriden_id=id_destino
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
           exception when others then
           --dbms_output.put_line('No existe estudiante/cuenta:'||id_destino);
           v_error := 'No existe estudiante/cuenta:'||id_destino;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||id_destino from dual;
                     RETURN (cur);
           end;
           --dbms_output.put_line('v_pidm_dest:'||v_pidm_dest);
           begin
           select spriden_pidm into v_pidm_dest_cta from spriden
           where spriden_id=cta_x_cobrar
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
           exception when others then
           --dbms_output.put_line('No existe estudiante/cuenta:'||cta_x_cobrar);
           v_error :=  'No existe estudiante/cuenta:'||cta_x_cobrar;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||cta_x_cobrar from dual;
                     RETURN (cur);
           end;
           
           --dbms_output.put_line('v_pidm_dest_cta:'||v_pidm_dest_cta);
           select count(*) into conta from tbraccd
           where tbraccd_pidm=v_pidm
           and     tbraccd_tran_number=tran_origen;
           --dbms_output.put_line('conta_origen:'||conta);
           
          if conta=0 then
          --dbms_output.put_line('No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen);
          v_error := 'No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen;
             open cur for select null, null, null, 'No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen from dual;
                    RETURN (cur);
          end if;
           
           select count(*) into conta from tbraccd, tbrappl
           where tbraccd_pidm=v_pidm
          and     tbraccd_tran_number=tran_origen
           and     tbrappl_pidm=tbraccd_pidm
           and     tbrappl_pay_tran_number=tbraccd_tran_number
           and     tbrappl_reappl_ind = 'Y';
           --dbms_output.put_line('conta_origen_reappl:'||conta);
           
           if conta=1 then
             v_error:= 'Estudiante/cuenta/transacción NO puede reasignarse se encuentra Cancelada:'||id_origen||' '||tran_origen;
              open cur for select null, null, null, 'Estudiante/cuenta/transacción NO puede reasignarse se encuentra Cancelada:'||id_origen||' '||tran_origen from dual;
                     RETURN (cur);
           end if;
 
           Begin

                    For pagoppl in (select TBRAPPL_PIDM, TBRAPPL_PAY_TRAN_NUMBER, TBRAPPL_CHG_TRAN_NUMBER, TBRAPPL_AMOUNT, TBRAPPL_DIRECT_PAY_TYPE
                                        from tbrappl 
                                        Where TBRAPPL_PIDM = v_pidm
                                        And TBRAPPL_PAY_TRAN_NUMBER = tran_origen
                                        And TBRAPPL_REAPPL_IND is null )  loop
                                                                                
                                        gb_common.p_set_context('TB_RECEIVABLE','PROCESS','APPLPMNT-FORCE','N');

                                       tv_application.p_unapply_by_tran_number( p_pidm               => pagoppl.TBRAPPL_PIDM,
                                                                                                      p_pay_tran_number    => pagoppl.TBRAPPL_PAY_TRAN_NUMBER,
                                                                                                      p_unapply_direct_pay => pagoppl.TBRAPPL_DIRECT_PAY_TYPE);   
                                                                                                                                              
                                                                               
                                      -- dbms_output.put_line('pidm:' ||pagoppl.TBRAPPL_PIDM||'pay_tran:'|| pagoppl.TBRAPPL_PAY_TRAN_NUMBER||' '||'chg_tran:'||  pagoppl.TBRAPPL_CHG_TRAN_NUMBER);                                              
                                                                                
                    End Loop pagoppl;
                                                        -- dbms_output.put_line('cancela - pago y actualiza varias tablas ');
                    
                    Begin 
                             select tbraccd_amount into monto_origen from tbraccd
                             where tbraccd_pidm=v_pidm
                             and     tbraccd_tran_number=tran_origen;
                             
                    Exception when others then
                        v_error := 'Error al recuperar el monto 5.1'||' := ' ||sqlerrm;
                        Open cur for select null, null, null, v_error from dual;
                        RETURN (cur);
                    End;

                                                   
                         --********CLONANDO EL REGISTRO CON TBRACCD_AMOUNT NEGATIVO Y TBRACCD_BALANCE = 0 **************--
                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                            into v_tran_cancela 
                        FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm;
                                        
                       begin
                        SELECT  tbbdetc_desc into desc_detl1
                        from tbbdetc
                        where cod_det1=tbbdetc_detail_code;
                        exception when others then
                        --dbms_output.put_line( 'No existe código detalle:');
                        v_error :=  'No existe código detalle 5.1:'||cod_det1;
                       open cur for select null, null, null, 'No existe código detalle 5.1:'||cod_det1 from dual;
                                 RETURN (cur);
                       end;  
                       
                        begin
                        SELECT  tbbdetc_desc into desc_detl2
                        from tbbdetc
                        where cod_det2=tbbdetc_detail_code;
                        exception when others then
                        --dbms_output.put_line( 'No existe código detalle:');
                        v_error := 'No existe código detalle 5.1:'||cod_det2;
                       open cur for select null, null, null, 'No existe código detalle 5.1:'||cod_det2 from dual;
                                 RETURN (cur);
                       end; 
                       
                       Begin 
                                        INSERT INTO TBRACCD
                                        (TBRACCD_PIDM
                                        ,TBRACCD_TRAN_NUMBER
                                        ,TBRACCD_TERM_CODE
                                        ,TBRACCD_DETAIL_CODE
                                        ,TBRACCD_USER
                                        ,TBRACCD_ENTRY_DATE
                                        ,TBRACCD_AMOUNT
                                        ,TBRACCD_BALANCE
                                        ,TBRACCD_EFFECTIVE_DATE
                                        ,TBRACCD_TRAN_NUMBER_PAID
                                        ,TBRACCD_DESC
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,TBRACCD_PAYMENT_ID
                                        ,TBRACCD_DOCUMENT_NUMBER
                                        ,TBRACCD_ACTIVITY_DATE
                                        ,TBRACCD_SESSION_NUMBER
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,TBRACCD_PERIOD
                                        ,TBRACCD_TRANS_DATE
                                        ,TBRACCD_FOREIGN_AMOUNT
                                        )
                                        SELECT 
                                        TBRACCD_PIDM
                                        ,v_tran_cancela
                                        ,TBRACCD_TERM_CODE
                                        ,cod_det1
                                        ,'POLIZAS'
                                        ,SYSDATE
                                        ,TBRACCD_AMOUNT  *-1
                                        ,0
                                        ,SYSDATE --DEBERA SER LA FECHA EN QUE SE POSTEO LA POLIZA
                                        ,tran_origen
                                        ,desc_detl1
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,num_pago
                                        ,num_docto
                                        ,SYSDATE
                                        ,0
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,folio
                                        ,TBRACCD_TRANS_DATE
                                        ,1
                                        FROM TBRACCD
                                        WHERE TBRACCD_PIDM =  v_pidm 
                                        AND TBRACCD_TRAN_NUMBER =tran_origen;-- '30535'
                        exception when others then
                        --dbms_output.put_line( 'No existe código detalle:');
                        v_error := 'Se presento un error al insertar tbraccd 5.1:'||sqlerrm;
                       open cur for select null, null, null, v_error from dual;
                                 RETURN (cur);
                       end; 
                                        
                                        
                                        
                --dbms_output.put_line('1 v_pidm:'|| v_pidm||' '||'v_tran_cancela:'|| v_tran_cancela||' '||'texto:'|| texto);            
             
                     Begin
                              v_error_transfer:=pkg_simoba.sp_reference( v_pidm, v_tran_cancela, texto);
                              
                               If v_error_transfer !=  'EXITO' then 
                                   v_error := 'Se presento un error al insertar text 5.1'||v_error_transfer;
                               End if;
                              
                              
                     exception when others then
                       --dbms_output.put_line( 'No existe código detalle:');
                      v_error := 'Se presento un error al insertar text 5.1:'||sqlerrm;
                     open cur for select null, null, null, v_error from dual;
                             RETURN (cur);
                     end; 
                              

                             --dbms_output.put_line('inserta registro cancela');
                     Begin       
                             update  tbraccd set tbraccd_balance=0
                             where tbraccd_pidm=v_pidm
                             and     tbraccd_tran_number=tran_origen;
                     exception when others then
                       --dbms_output.put_line( 'No existe código detalle:');
                      v_error := 'Se presento un error al actualizar tbraccd 5.1:'||sqlerrm;
                     open cur for select null, null, null, v_error from dual;
                             RETURN (cur);
                     end; 
                             
                     Begin                                                                                                                        
                             Update TVRACCD
                             set TVRACCD_BALANCE = 0
                             Where TVRACCD_PIDM = v_pidm
                             And TVRACCD_ACCD_TRAN_NUMBER = tran_origen;      
                     Exception   
                     When Others  then
                      v_error :=  'Se presento un error al actualizar TVRACCD 5.1:'||sqlerrm;
                     open cur for select null, null, null,v_error from dual;
                             RETURN (cur);
                     end; 
                                                                                   


                    Begin
                            select to_char(tbraccd_trans_date,'dd/mm/rrrr') 
                                into f_tran
                            from tbraccd
                            where tbraccd_pidm = v_pidm --
                            and     tbraccd_tran_number=tran_origen; 
                    Exception
                    When Others  then 
                      v_error :=  'Se presento un error al actualizar TVRACCD 5.1:'||sqlerrm;
                     open cur for select null, null, null,v_error from dual;
                             RETURN (cur);
                    end;                             

                    periodo:= fget_periodo_general(substr(id_destino,1,2),f_tran) ;   


                                     --********CLONANDO EL REGISTRO CON TBRACCD_AMOUNT NEGATIVO PARA LA CUENTA POR COBRAR  **************--
                                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 into v_tran_x_cobrar FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm_dest_cta;
                                        
                     Begin           
                                        INSERT INTO TBRACCD
                                        (TBRACCD_PIDM
                                        ,TBRACCD_TRAN_NUMBER
                                        ,TBRACCD_TERM_CODE
                                        ,TBRACCD_DETAIL_CODE
                                        ,TBRACCD_USER
                                        ,TBRACCD_ENTRY_DATE
                                        ,TBRACCD_AMOUNT
                                        ,TBRACCD_BALANCE
                                        ,TBRACCD_EFFECTIVE_DATE
                                        ,TBRACCD_TRAN_NUMBER_PAID
                                        ,TBRACCD_DESC
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,TBRACCD_PAYMENT_ID
                                        ,TBRACCD_DOCUMENT_NUMBER
                                        ,TBRACCD_ACTIVITY_DATE
                                        ,TBRACCD_SESSION_NUMBER
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,TBRACCD_PERIOD
                                        ,TBRACCD_TRANS_DATE
                                        )
                                        SELECT 
                                        v_pidm_cta
                                        ,v_tran_x_cobrar
                                        ,periodo
                                        ,cod_det2
                                        ,'POLIZAS'
                                        ,SYSDATE
                                        ,TBRACCD_AMOUNT *-1
                                        ,TBRACCD_AMOUNT
                                        ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL POSTEO--
                                        ,null
                                        ,desc_detl2
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,num_pago
                                        ,num_docto
                                        ,SYSDATE
                                        ,0
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,folio
                                        ,TBRACCD_TRANS_DATE    --DEBERA SER LA FECHA EN QUE SE HIZO EL PAGO TRANSACCION--
                                        FROM TBRACCD
                                        WHERE TBRACCD_PIDM =  v_pidm
                                        AND TBRACCD_TRAN_NUMBER =tran_origen;
                     Exception        
                     When Others then
                      v_error := 'Se presento un error al insertar TBRACCD 5.2:'||sqlerrm;
                     open cur for select null, null, null, v_error from dual;
                             RETURN (cur);
                     end; 
                                        
                                        
                                          --dbms_output.put_line('inserta registro cta x cobrar');               
     
--dbms_output.put_line('2 v_pidm_dest:'|| v_pidm_dest||' '||'v_tran_x_cobrar:'|| v_tran_x_cobrar||' '||'texto:'|| texto);    
                    Begin
                            v_error_transfer:=pkg_simoba.sp_reference( v_pidm_cta, v_tran_x_cobrar, texto);
                            
                        If v_error_transfer !=  'EXITO' then 
                           v_error := 'Error al Insertar Texto bloque3.1 '||v_error_transfer;
                        End if;

                    Exception    
                    When Others then     
                      --v_error := sqlerrm;
                     open cur for select null, null, null, 'Se presento un error al insertar texto 5.1:'||v_error_transfer from dual;
                             RETURN (cur);
                    End; 

 
                
                            --********REALIZANDO LA TRANSFERENCIA**************--
                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                            into v_tran_transfiere 
                        FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm_dest;
                        
                    Begin
                        
                           INSERT INTO TBRACCD
                                    (TBRACCD_PIDM
                                    ,TBRACCD_TRAN_NUMBER
                                    ,TBRACCD_TERM_CODE
                                    ,TBRACCD_DETAIL_CODE
                                    ,TBRACCD_USER
                                    ,TBRACCD_ENTRY_DATE
                                    ,TBRACCD_AMOUNT
                                    ,TBRACCD_BALANCE
                                    ,TBRACCD_EFFECTIVE_DATE
                                    ,TBRACCD_DESC
                                    ,TBRACCD_CROSSREF_DETAIL_CODE
                                    ,TBRACCD_SRCE_CODE
                                    ,TBRACCD_ACCT_FEED_IND
                                    ,TBRACCD_ACTIVITY_DATE
                                    ,TBRACCD_SESSION_NUMBER
                                    ,TBRACCD_TRANS_DATE
                                    ,TBRACCD_PAYMENT_ID
                                    ,TBRACCD_DOCUMENT_NUMBER
                                    ,TBRACCD_CURR_CODE
                                    ,TBRACCD_DATA_ORIGIN
                                    ,TBRACCD_CREATE_SOURCE
                                    ,TBRACCD_SURROGATE_ID
                                    ,TBRACCD_VERSION
                                    ,TBRACCD_PERIOD
                                    ,TBRACCD_FOREIGN_AMOUNT
                                    )
                                    SELECT 
                                     v_pidm_dest 
                                    ,v_tran_transfiere
                                    ,periodo
                                    ,cod_det2
                                    ,'POLIZAS'
                                    ,SYSDATE
                                    ,TBRACCD_AMOUNT
                                    ,TBRACCD_AMOUNT *-1
                                    ,SYSDATE --DEBERA SER LA FECHA EN QUE SE POSTEO LA POLIZA--
                                    ,desc_detl2
                                    ,TBRACCD_CROSSREF_DETAIL_CODE
                                    ,TBRACCD_SRCE_CODE
                                    ,TBRACCD_ACCT_FEED_IND
                                    ,SYSDATE
                                    ,TBRACCD_SESSION_NUMBER
                                    ,TBRACCD_TRANS_DATE
                                    ,num_pago
                                    ,num_docto
                                    ,TBRACCD_CURR_CODE
                                    ,TBRACCD_DATA_ORIGIN
                                    ,TBRACCD_CREATE_SOURCE
                                    ,TBRACCD_SURROGATE_ID
                                    ,TBRACCD_VERSION
                                    ,folio
                                    ,2
                                    FROM TBRACCD
                                    WHERE TBRACCD_PIDM = v_pidm 
                                    AND TBRACCD_TRAN_NUMBER = tran_origen;--'30535'      
                                    
                    Exception    
                    When Others then   
                      v_error := 'Se presento un error al insertar Tbraccd 5.2: '||sqlerrm;
                     open cur for select null, null, null, v_error from dual;
                             RETURN (cur);
                    End; 
                                    
                                    
                  --dbms_output.put_line('3 v_pidm_dest:'|| v_pidm_dest||' '||'v_tran_transfiere:'|| v_tran_transfiere||' '||'texto:'|| texto);  
                    Begin
                            v_error_transfer:=pkg_simoba.sp_reference( v_pidm_dest, v_tran_transfiere, texto);
                            
                            If v_error_transfer !=  'EXITO' then 
                               v_error := 'Error al Insertar Texto bloque3.1 '||v_error_transfer;
                            End if;

                    Exception        
                      --v_error := sqlerrm;
                      When Others then 
                     open cur for select null, null, null, 'Se presento un error al insertar Texto 5.2:'||v_error_transfer from dual;
                             RETURN (cur);
                    End; 
                            
                         
                            --********REALIZANDO LA TRANSFERENCIA CUENTA POR PAGAR **************--
                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                            into v_tran_x_pagar 
                        FROM TBRACCD 
                        WHERE TBRACCD_PIDM = v_pidm_dest_cta;
                        
                        Begin
                                   INSERT INTO TBRACCD
                                            (TBRACCD_PIDM
                                            ,TBRACCD_TRAN_NUMBER
                                            ,TBRACCD_TERM_CODE
                                            ,TBRACCD_DETAIL_CODE
                                            ,TBRACCD_USER
                                            ,TBRACCD_ENTRY_DATE
                                            ,TBRACCD_AMOUNT
                                            ,TBRACCD_BALANCE
                                            ,TBRACCD_EFFECTIVE_DATE
                                            ,TBRACCD_DESC
                                            ,TBRACCD_CROSSREF_DETAIL_CODE
                                            ,TBRACCD_SRCE_CODE
                                            ,TBRACCD_ACCT_FEED_IND
                                            ,TBRACCD_ACTIVITY_DATE
                                            ,TBRACCD_SESSION_NUMBER
                                            ,TBRACCD_TRANS_DATE
                                            ,TBRACCD_PAYMENT_ID
                                            ,TBRACCD_DOCUMENT_NUMBER
                                            ,TBRACCD_CURR_CODE
                                            ,TBRACCD_DATA_ORIGIN
                                            ,TBRACCD_CREATE_SOURCE
                                            ,TBRACCD_SURROGATE_ID
                                            ,TBRACCD_VERSION
                                            ,TBRACCD_PERIOD
                                            )
                                            SELECT 
                                             v_pidm_dest_cta
                                            ,v_tran_x_pagar
                                            ,TBRACCD_TERM_CODE
                                            ,cod_det1
                                            ,'POLIZAS'
                                            ,SYSDATE
                                            ,TBRACCD_AMOUNT
                                            ,TBRACCD_AMOUNT * -1
                                            ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL POSTEO--
                                            ,desc_detl1
                                            ,TBRACCD_CROSSREF_DETAIL_CODE
                                            ,TBRACCD_SRCE_CODE
                                            ,TBRACCD_ACCT_FEED_IND
                                            ,SYSDATE
                                            ,TBRACCD_SESSION_NUMBER
                                            ,TBRACCD_TRANS_DATE
                                            ,num_pago
                                            ,num_docto
                                            ,TBRACCD_CURR_CODE
                                            ,TBRACCD_DATA_ORIGIN
                                            ,TBRACCD_CREATE_SOURCE
                                            ,TBRACCD_SURROGATE_ID
                                            ,TBRACCD_VERSION
                                            ,folio
                                            FROM TBRACCD
                                            WHERE TBRACCD_PIDM = v_pidm 
                                            AND TBRACCD_TRAN_NUMBER = tran_origen;--'30535'   
                        Exception     
                        When Others then    
                          v_error := 'Se presento un error al insertar Tbraccd 5.3: '||sqlerrm;
                         open cur for select null, null, null, v_error from dual;
                                 RETURN (cur);
                        End; 

                        Begin
                                v_error_transfer:=pkg_simoba.sp_reference( v_pidm_dest_cta, v_tran_x_pagar, texto);
                                If v_error_transfer !=  'EXITO' then 
                                   v_error := 'Se presento un error al insertar Texto 5.3 '||v_error_transfer;
                                End if;
                                
                                
                        Exception     
                        When Others then     
                          --v_error := sqlerrm;
                         open cur for select null, null, null, 'Se presento un error al insertar Texto 5.3:'||v_error_transfer from dual;
                                 RETURN (cur);
                        End; 
                         
                                    
                                   
                        --***********************INSERTANDO  EN  LA  TABLA  BITACORA CANCELACION************************--
                        Begin
                                INSERT INTO TBITANI
                                (
                                TBITANI_FOLIO
                                ,TBITANI_TIPO_POLIZA
                                ,TBITANI_PIDM_ORIGEN 
                                ,TBITANI_MONTO_ORIGEN
                                ,TBITANI_TRAN_NUMBER_ORIGEN
                                ,TBITANI_TRAN_NUMBER_CANCELA
                                ,TBITANI_FECHA_TRAN
                                ,TBITANI_PIDM_DESTINO --(p_matricula)
                                ,TBITANI_TRAN_NUMBER_DESTINO
                                ,TBITANI_MONTO_DESINO
                                ,TBITANI_ACTIVITY_DATE
                                ,TBITANI_PROCESO_ID
                                )
                                SELECT
                                folio,
                                'RI',
                                v_pidm --PIDM ORIGEN--
                                ,monto_origen --MONTO ORIGEN--
                                ,tran_origen --TBRACCD_TRAN_NUMBER ORIGEN--
                                ,v_tran_cancela -- Transacción que cancela
                                ,TBRACCD_ENTRY_DATE -- FECHA DE TRANSACCION--
                                ,v_pidm_dest --PIDM DESTINO--
                                ,v_tran_transfiere
                                ,monto_origen --MONTO DESTINO
                                ,SYSDATE --FECHA DEL SISTEMA--
                                ,(select nvl(max(tbitani_proceso_id),0)+1 from tbitani
                                   where tbitani_folio=folio) --ID DEPROCESO (NO IDENTIFICADOS
                                            FROM TBRACCD
                                            WHERE TBRACCD_PIDM = v_pidm 
                                            AND TBRACCD_TRAN_NUMBER = tran_origen;
                        Exception        
                        When Others then  
                          v_error :=  'Se presento un error al insertar TBITANI 5.3:'||sqlerrm;
                         open cur for select null, null, null,v_error from dual;
                                 RETURN (cur);
                        End; 

                        --***********************INSERTANDO  EN  LA  TABLA  BITACORA CXC Y CXP************************--   
                        Begin
                                 
                                INSERT INTO TBITANI
                                (
                                TBITANI_FOLIO
                                ,TBITANI_TIPO_POLIZA
                                ,TBITANI_PIDM_ORIGEN 
                                ,TBITANI_MONTO_ORIGEN
                                ,TBITANI_TRAN_NUMBER_ORIGEN
                                ,TBITANI_TRAN_NUMBER_CANCELA
                                ,TBITANI_FECHA_TRAN
                                ,TBITANI_PIDM_DESTINO --(p_matricula)
                                ,TBITANI_TRAN_NUMBER_DESTINO
                                ,TBITANI_MONTO_DESINO
                                ,TBITANI_ACTIVITY_DATE
                                ,TBITANI_PROCESO_ID
                                )
                                SELECT
                                folio,
                                'RI',
                                v_pidm_dest_cta --PIDM ORIGEN--
                                ,monto_origen --MONTO ORIGEN--
                                ,tran_origen --TBRACCD_TRAN_NUMBER ORIGEN--
                                ,v_tran_x_cobrar -- Transacción que cancela
                                ,TBRACCD_ENTRY_DATE -- FECHA DE TRANSACCION--
                                ,v_pidm_cta --PIDM DESTINO--
                                ,v_tran_x_pagar
                                ,monto_origen --MONTO DESTINO
                                ,SYSDATE --FECHA DEL SISTEMA--
                                ,(select nvl(max(tbitani_proceso_id),0)+1 from tbitani
                                   where tbitani_folio=folio) --ID DEPROCESO (NO IDENTIFICADOS
                                            FROM TBRACCD
                                            WHERE TBRACCD_PIDM = v_pidm 
                                            AND TBRACCD_TRAN_NUMBER = tran_origen;
                        Exception        
                        When Others then  
                          v_error :=  'Se presento un error al insertar TBITANI 5.4:'||sqlerrm;
                         open cur for select null, null, null,v_error from dual;
                                 RETURN (cur);
                        End; 
                                            
                        COMMIT;
    --                     dbms_output.put_line('inserta registro bitacora');
      
                         If v_error is null then       
                                               v_error:='Proceso exitoso';
                                               open cur for select a.spriden_id, tbitani_tran_number_cancela, b.spriden_id, tbitani_tran_number_destino
                                                                   from tbitani, spriden a, spriden b
                                                                   where tbitani_pidm_origen=a.spriden_pidm
                                                                   and     tbitani_pidm_destino=b.spriden_pidm
                                                                   and     tbitani_folio=folio;
                                                RETURN (cur);           
                         Else
                               open cur for select null, null, null,  v_error from dual;
                                         RETURN (cur);
                                 --return(v_error );
                          End if;    
                                                                                                                       

    Exception
    When Others then 
    dbms_output.put_line('error:'||sqlerrm);
    v_error:='ERROR PKG_TRANSFERENCIA: ' || SQLERRM;
    open cur for select null, null, null,v_error  from dual;
                    RETURN (cur);
    End;

End REASIG_INTERCOM;   

function  REASIG_INTERCAMP (folio IN varchar2, id_origen IN VARCHAR2,  tran_origen in number,  id_destino IN varchar2,  num_pago in varchar2, num_docto in varchar2, texto in varchar2,
                                            cod_det1 IN varchar2, cod_det2 IN varchar2 )  
RETURN  PKG_TRANSFERENCIA.products_type  
  IS 

v_pidm number;
v_pidm_cta number;
v_pidm_dest number;
v_pidm_dest_cta number;
conta    number;
v_tran_cancela number;
v_tran_diferencia number;
v_tran_transfiere number;
v_tran_x_cobrar  number;
v_tran_x_pagar   number;
monto_origen decimal(16,2);
v_error    varchar2(2000);
longitud number;
t1         varchar2(60);
t2         varchar2(60);
t3         varchar2(60);
desc_detl1 varchar2(30);
desc_detl2 varchar2(30);
periodo   varchar2(6);
f_tran      varchar2(10);
ptex3 varchar2(4000);
v_error_transfer  varchar2(4000);

cur pkg_transferencia.products_type;
begin
 
                
        v_error := null;

          begin
           select spriden_pidm into v_pidm 
           from spriden
           where spriden_id=id_origen
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
          exception when others then
          -- dbms_output.put_line('No existe estudiante/cuenta:'||id_origen);
          v_error := 'No existe estudiante/cuenta:'||id_origen;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||id_origen from dual;
                     RETURN (cur);
          end;
          
          -- dbms_output.put_line('v_pidm:'||v_pidm);          
           
           dbms_output.put_line('v_pidm_cta:'||v_pidm_cta);
           begin
           select spriden_pidm into v_pidm_dest from spriden
           where spriden_id=id_destino
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
           exception when others then
           --dbms_output.put_line('No existe estudiante/cuenta:'||id_destino);
           v_error := 'No existe estudiante/cuenta:'||id_destino;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||id_destino from dual;
                     RETURN (cur);
           end;
           --dbms_output.put_line('v_pidm_dest:'||v_pidm_dest);
          
           --dbms_output.put_line('v_pidm_dest_cta:'||v_pidm_dest_cta);
           select count(*) into conta from tbraccd
           where tbraccd_pidm=v_pidm
           and     tbraccd_tran_number=tran_origen;
           --dbms_output.put_line('conta_origen:'||conta);
           
          if conta=0 then
          --dbms_output.put_line('No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen);
          v_error := 'No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen;
             open cur for select null, null, null, 'No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen from dual;
                    RETURN (cur);
          end if;
           
           select count(*) into conta from tbraccd, tbrappl
           where tbraccd_pidm=v_pidm
          and     tbraccd_tran_number=tran_origen
           and     tbrappl_pidm=tbraccd_pidm
           and     tbrappl_pay_tran_number=tbraccd_tran_number
           and     tbrappl_reappl_ind = 'Y';
           --dbms_output.put_line('conta_origen_reappl:'||conta);
           
           if conta=1 then
             v_error:= 'Estudiante/cuenta/transacción NO puede reasignarse se encuentra Cancelada:'||id_origen||' '||tran_origen;
              open cur for select null, null, null, 'Estudiante/cuenta/transacción NO puede reasignarse se encuentra Cancelada:'||id_origen||' '||tran_origen from dual;
                     RETURN (cur);
           end if;
 
           Begin

                    For pagoppl in (select TBRAPPL_PIDM, TBRAPPL_PAY_TRAN_NUMBER, TBRAPPL_CHG_TRAN_NUMBER, TBRAPPL_AMOUNT, TBRAPPL_DIRECT_PAY_TYPE
                                        from tbrappl 
                                        Where TBRAPPL_PIDM = v_pidm
                                        And TBRAPPL_PAY_TRAN_NUMBER = tran_origen
                                        And TBRAPPL_REAPPL_IND is null )  loop
                                                                                
                                        gb_common.p_set_context('TB_RECEIVABLE','PROCESS','APPLPMNT-FORCE','N');

                                       tv_application.p_unapply_by_tran_number( p_pidm               => pagoppl.TBRAPPL_PIDM,
                                                                                                      p_pay_tran_number    => pagoppl.TBRAPPL_PAY_TRAN_NUMBER,
                                                                                                      p_unapply_direct_pay => pagoppl.TBRAPPL_DIRECT_PAY_TYPE);   
                                                                                                                                              
                                                                               
                                      -- dbms_output.put_line('pidm:' ||pagoppl.TBRAPPL_PIDM||'pay_tran:'|| pagoppl.TBRAPPL_PAY_TRAN_NUMBER||' '||'chg_tran:'||  pagoppl.TBRAPPL_CHG_TRAN_NUMBER);                                              
                                                                                
                    End Loop pagoppl;
                                                        -- dbms_output.put_line('cancela - pago y actualiza varias tablas ');
                    
                    Begin 
                             select tbraccd_amount into monto_origen from tbraccd
                             where tbraccd_pidm=v_pidm
                             and     tbraccd_tran_number=tran_origen;
                             
                    Exception when others then
                        v_error := 'Error al recuperar el monto 5.1'||' := ' ||sqlerrm;
                        Open cur for select null, null, null, v_error from dual;
                        RETURN (cur);
                    End;

                                                   
                         --********CLONANDO EL REGISTRO CON TBRACCD_AMOUNT NEGATIVO Y TBRACCD_BALANCE = 0 **************--
                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                            into v_tran_cancela 
                        FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm;
                                        
                       begin
                        SELECT  tbbdetc_desc into desc_detl1
                        from tbbdetc
                        where cod_det1=tbbdetc_detail_code;
                        exception when others then
                        --dbms_output.put_line( 'No existe código detalle:');
                        v_error :=  'No existe código detalle 5.1:'||cod_det1;
                       open cur for select null, null, null, 'No existe código detalle 5.1:'||cod_det1 from dual;
                                 RETURN (cur);
                       end;  
                       
                        begin
                        SELECT  tbbdetc_desc into desc_detl2
                        from tbbdetc
                        where cod_det2=tbbdetc_detail_code;
                        exception when others then
                        --dbms_output.put_line( 'No existe código detalle:');
                        v_error := 'No existe código detalle 5.1:'||cod_det2;
                       open cur for select null, null, null, 'No existe código detalle 5.1:'||cod_det2 from dual;
                                 RETURN (cur);
                       end; 
                       
                       Begin 
                                        INSERT INTO TBRACCD
                                        (TBRACCD_PIDM
                                        ,TBRACCD_TRAN_NUMBER
                                        ,TBRACCD_TERM_CODE
                                        ,TBRACCD_DETAIL_CODE
                                        ,TBRACCD_USER
                                        ,TBRACCD_ENTRY_DATE
                                        ,TBRACCD_AMOUNT
                                        ,TBRACCD_BALANCE
                                        ,TBRACCD_EFFECTIVE_DATE
                                        ,TBRACCD_TRAN_NUMBER_PAID
                                        ,TBRACCD_DESC
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,TBRACCD_PAYMENT_ID
                                        ,TBRACCD_DOCUMENT_NUMBER
                                        ,TBRACCD_ACTIVITY_DATE
                                        ,TBRACCD_SESSION_NUMBER
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,TBRACCD_PERIOD
                                        ,TBRACCD_TRANS_DATE
                                        ,TBRACCD_FOREIGN_AMOUNT
                                        )
                                        SELECT 
                                        TBRACCD_PIDM
                                        ,v_tran_cancela
                                        ,TBRACCD_TERM_CODE
                                        ,cod_det1
                                        ,'POLIZAS'
                                        ,SYSDATE
                                        ,TBRACCD_AMOUNT  *-1
                                        ,0
                                        ,SYSDATE --DEBERA SER LA FECHA EN QUE SE POSTEO LA POLIZA
                                        ,tran_origen
                                        ,desc_detl1
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,num_pago
                                        ,num_docto
                                        ,SYSDATE
                                        ,0
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,folio
                                        ,TBRACCD_TRANS_DATE
                                        ,1
                                        FROM TBRACCD
                                        WHERE TBRACCD_PIDM =  v_pidm 
                                        AND TBRACCD_TRAN_NUMBER =tran_origen;-- '30535'
                        exception when others then
                        --dbms_output.put_line( 'No existe código detalle:');
                        v_error := 'Se presento un error al insertar tbraccd 5.1:'||sqlerrm;
                       open cur for select null, null, null, v_error from dual;
                                 RETURN (cur);
                       end; 
                                        
                                        
                                        
                --dbms_output.put_line('1 v_pidm:'|| v_pidm||' '||'v_tran_cancela:'|| v_tran_cancela||' '||'texto:'|| texto);            
             
                     Begin
                              v_error_transfer:=pkg_simoba.sp_reference( v_pidm, v_tran_cancela, texto);
                              
                               If v_error_transfer !=  'EXITO' then 
                                   v_error := 'Se presento un error al insertar text 5.1'||v_error_transfer;
                               End if;
                              
                              
                     exception when others then
                       --dbms_output.put_line( 'No existe código detalle:');
                      v_error := 'Se presento un error al insertar text 5.1:'||sqlerrm;
                     open cur for select null, null, null, v_error from dual;
                             RETURN (cur);
                     end; 
                              

                             --dbms_output.put_line('inserta registro cancela');
                     Begin       
                             update  tbraccd set tbraccd_balance=0
                             where tbraccd_pidm=v_pidm
                             and     tbraccd_tran_number=tran_origen;
                     exception when others then
                       --dbms_output.put_line( 'No existe código detalle:');
                      v_error := 'Se presento un error al actualizar tbraccd 5.1:'||sqlerrm;
                     open cur for select null, null, null, v_error from dual;
                             RETURN (cur);
                     end; 
                             
                     Begin                                                                                                                        
                             Update TVRACCD
                             set TVRACCD_BALANCE = 0
                             Where TVRACCD_PIDM = v_pidm
                             And TVRACCD_ACCD_TRAN_NUMBER = tran_origen;      
                     Exception   
                     When Others  then
                      v_error :=  'Se presento un error al actualizar TVRACCD 5.1:'||sqlerrm;
                     open cur for select null, null, null,v_error from dual;
                             RETURN (cur);
                     end; 
                                                                                   


                    Begin
                            select to_char(tbraccd_trans_date,'dd/mm/rrrr') 
                                into f_tran
                            from tbraccd
                            where tbraccd_pidm = v_pidm --
                            and     tbraccd_tran_number=tran_origen; 
                    Exception
                    When Others  then 
                      v_error :=  'Se presento un error al actualizar TVRACCD 5.1:'||sqlerrm;
                     open cur for select null, null, null,v_error from dual;
                             RETURN (cur);
                    end;                             

                    periodo:= fget_periodo_general(substr(id_destino,1,2),f_tran) ;   

                
                            --********REALIZANDO LA TRANSFERENCIA**************--
                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                            into v_tran_transfiere 
                        FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm_dest;
                        
                    Begin
                        
                           INSERT INTO TBRACCD
                                    (TBRACCD_PIDM
                                    ,TBRACCD_TRAN_NUMBER
                                    ,TBRACCD_TERM_CODE
                                    ,TBRACCD_DETAIL_CODE
                                    ,TBRACCD_USER
                                    ,TBRACCD_ENTRY_DATE
                                    ,TBRACCD_AMOUNT
                                    ,TBRACCD_BALANCE
                                    ,TBRACCD_EFFECTIVE_DATE
                                    ,TBRACCD_DESC
                                    ,TBRACCD_CROSSREF_DETAIL_CODE
                                    ,TBRACCD_SRCE_CODE
                                    ,TBRACCD_ACCT_FEED_IND
                                    ,TBRACCD_ACTIVITY_DATE
                                    ,TBRACCD_SESSION_NUMBER
                                    ,TBRACCD_TRANS_DATE
                                    ,TBRACCD_PAYMENT_ID
                                    ,TBRACCD_DOCUMENT_NUMBER
                                    ,TBRACCD_CURR_CODE
                                    ,TBRACCD_DATA_ORIGIN
                                    ,TBRACCD_CREATE_SOURCE
                                    ,TBRACCD_SURROGATE_ID
                                    ,TBRACCD_VERSION
                                    ,TBRACCD_PERIOD
                                    ,TBRACCD_FOREIGN_AMOUNT
                                    )
                                    SELECT 
                                     v_pidm_dest 
                                    ,v_tran_transfiere
                                    ,periodo
                                    ,cod_det2
                                    ,'POLIZAS'
                                    ,SYSDATE
                                    ,TBRACCD_AMOUNT
                                    ,TBRACCD_AMOUNT *-1
                                    ,SYSDATE --DEBERA SER LA FECHA EN QUE SE POSTEO LA POLIZA--
                                    ,desc_detl2
                                    ,TBRACCD_CROSSREF_DETAIL_CODE
                                    ,TBRACCD_SRCE_CODE
                                    ,TBRACCD_ACCT_FEED_IND
                                    ,SYSDATE
                                    ,TBRACCD_SESSION_NUMBER
                                    ,TBRACCD_TRANS_DATE
                                    ,num_pago
                                    ,num_docto
                                    ,TBRACCD_CURR_CODE
                                    ,TBRACCD_DATA_ORIGIN
                                    ,TBRACCD_CREATE_SOURCE
                                    ,TBRACCD_SURROGATE_ID
                                    ,TBRACCD_VERSION
                                    ,folio
                                    ,2
                                    FROM TBRACCD
                                    WHERE TBRACCD_PIDM = v_pidm 
                                    AND TBRACCD_TRAN_NUMBER = tran_origen;--'30535'      
                                    
                    Exception    
                    When Others then   
                      v_error := 'Se presento un error al insertar Tbraccd 5.2: '||sqlerrm;
                     open cur for select null, null, null, v_error from dual;
                             RETURN (cur);
                    End; 
                                    
                                    
                  --dbms_output.put_line('3 v_pidm_dest:'|| v_pidm_dest||' '||'v_tran_transfiere:'|| v_tran_transfiere||' '||'texto:'|| texto);  
                    Begin
                            v_error_transfer:=pkg_simoba.sp_reference( v_pidm_dest, v_tran_transfiere, texto);
                            
                            If v_error_transfer !=  'EXITO' then 
                               v_error := 'Error al Insertar Texto bloque3.1 '||v_error_transfer;
                            End if;

                    Exception        
                      --v_error := sqlerrm;
                      When Others then 
                     open cur for select null, null, null, 'Se presento un error al insertar Texto 5.2:'||v_error_transfer from dual;
                             RETURN (cur);
                    End; 
                            
                                    
                                   
                        --***********************INSERTANDO  EN  LA  TABLA  BITACORA CANCELACION************************--
                        Begin
                                INSERT INTO TBITANI
                                (
                                TBITANI_FOLIO
                                ,TBITANI_TIPO_POLIZA
                                ,TBITANI_PIDM_ORIGEN 
                                ,TBITANI_MONTO_ORIGEN
                                ,TBITANI_TRAN_NUMBER_ORIGEN
                                ,TBITANI_TRAN_NUMBER_CANCELA
                                ,TBITANI_FECHA_TRAN
                                ,TBITANI_PIDM_DESTINO --(p_matricula)
                                ,TBITANI_TRAN_NUMBER_DESTINO
                                ,TBITANI_MONTO_DESINO
                                ,TBITANI_ACTIVITY_DATE
                                ,TBITANI_PROCESO_ID
                                )
                                SELECT
                                folio,
                                'RI',
                                v_pidm --PIDM ORIGEN--
                                ,monto_origen --MONTO ORIGEN--
                                ,tran_origen --TBRACCD_TRAN_NUMBER ORIGEN--
                                ,v_tran_cancela -- Transacción que cancela
                                ,TBRACCD_ENTRY_DATE -- FECHA DE TRANSACCION--
                                ,v_pidm_dest --PIDM DESTINO--
                                ,v_tran_transfiere
                                ,monto_origen --MONTO DESTINO
                                ,SYSDATE --FECHA DEL SISTEMA--
                                ,(select nvl(max(tbitani_proceso_id),0)+1 from tbitani
                                   where tbitani_folio=folio) --ID DEPROCESO (NO IDENTIFICADOS
                                            FROM TBRACCD
                                            WHERE TBRACCD_PIDM = v_pidm 
                                            AND TBRACCD_TRAN_NUMBER = tran_origen;
                        Exception        
                        When Others then  
                          v_error :=  'Se presento un error al insertar TBITANI 5.3:'||sqlerrm;
                         open cur for select null, null, null,v_error from dual;
                                 RETURN (cur);
                        End; 

  
                                            
                        COMMIT;
    --                     dbms_output.put_line('inserta registro bitacora');
      
                         If v_error is null then       
                                               v_error:='Proceso exitoso';
                                               open cur for select a.spriden_id, tbitani_tran_number_cancela, b.spriden_id, tbitani_tran_number_destino
                                                                   from tbitani, spriden a, spriden b
                                                                   where tbitani_pidm_origen=a.spriden_pidm
                                                                   and     tbitani_pidm_destino=b.spriden_pidm
                                                                   and     tbitani_folio=folio;
                                                RETURN (cur);           
                         Else
                               open cur for select null, null, null,  v_error from dual;
                                         RETURN (cur);
                                 --return(v_error );
                          End if;    
                                                                                                                       

    Exception
    When Others then 
    dbms_output.put_line('error:'||sqlerrm);
    v_error:='ERROR PKG_TRANSFERENCIA: ' || SQLERRM;
    open cur for select null, null, null,v_error  from dual;
                    RETURN (cur);
    End;

End REASIG_INTERCAMP;   

function  REASIG_CAMP (folio IN varchar2, id_origen IN VARCHAR2,  tran_origen in number,  id_destino IN varchar2,  num_pago in varchar2, num_docto in varchar2, texto in varchar2,
                                            cod_det1 IN varchar2, cod_det2 IN varchar2 )  
RETURN  PKG_TRANSFERENCIA.products_type  
  IS 

v_pidm number;
v_pidm_cta number;
v_pidm_dest number;
v_pidm_dest_cta number;
conta    number;
v_tran_cancela number;
v_tran_diferencia number;
v_tran_transfiere number;
v_tran_x_cobrar  number;
v_tran_x_pagar   number;
monto_origen decimal(16,2);
v_error    varchar2(2000);
longitud number;
t1         varchar2(60);
t2         varchar2(60);
t3         varchar2(60);
desc_detl1 varchar2(30);
desc_detl2 varchar2(30);
periodo   varchar2(6);
f_tran      varchar2(10);
ptex3 varchar2(4000);
v_error_transfer  varchar2(4000);

cur pkg_transferencia.products_type;
begin
 
                
        v_error := null;

          begin
           select spriden_pidm into v_pidm 
           from spriden
           where spriden_id=id_origen
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
          exception when others then
          -- dbms_output.put_line('No existe estudiante/cuenta:'||id_origen);
          v_error := 'No existe estudiante/cuenta:'||id_origen;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||id_origen from dual;
                     RETURN (cur);
          end;
          
          -- dbms_output.put_line('v_pidm:'||v_pidm);          
           
           dbms_output.put_line('v_pidm_cta:'||v_pidm_cta);
           begin
           select spriden_pidm into v_pidm_dest from spriden
           where spriden_id=id_destino
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
           exception when others then
           --dbms_output.put_line('No existe estudiante/cuenta:'||id_destino);
           v_error := 'No existe estudiante/cuenta:'||id_destino;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||id_destino from dual;
                     RETURN (cur);
           end;
           --dbms_output.put_line('v_pidm_dest:'||v_pidm_dest);
          
           --dbms_output.put_line('v_pidm_dest_cta:'||v_pidm_dest_cta);
           select count(*) into conta from tbraccd
           where tbraccd_pidm=v_pidm
           and     tbraccd_tran_number=tran_origen;
           --dbms_output.put_line('conta_origen:'||conta);
           
          if conta=0 then
          --dbms_output.put_line('No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen);
          v_error := 'No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen;
             open cur for select null, null, null, 'No existe estudiante/cuenta/transacción:'||id_origen||' '||tran_origen from dual;
                    RETURN (cur);
          end if;
           
           select count(*) into conta from tbraccd, tbrappl
           where tbraccd_pidm=v_pidm
          and     tbraccd_tran_number=tran_origen
           and     tbrappl_pidm=tbraccd_pidm
           and     tbrappl_pay_tran_number=tbraccd_tran_number
           and     tbrappl_reappl_ind = 'Y';
           --dbms_output.put_line('conta_origen_reappl:'||conta);
           
           if conta=1 then
             v_error:= 'Estudiante/cuenta/transacción NO puede reasignarse se encuentra Cancelada:'||id_origen||' '||tran_origen;
              open cur for select null, null, null, 'Estudiante/cuenta/transacción NO puede reasignarse se encuentra Cancelada:'||id_origen||' '||tran_origen from dual;
                     RETURN (cur);
           end if;
 
           Begin

                    For pagoppl in (select TBRAPPL_PIDM, TBRAPPL_PAY_TRAN_NUMBER, TBRAPPL_CHG_TRAN_NUMBER, TBRAPPL_AMOUNT, TBRAPPL_DIRECT_PAY_TYPE
                                        from tbrappl 
                                        Where TBRAPPL_PIDM = v_pidm
                                        And TBRAPPL_PAY_TRAN_NUMBER = tran_origen
                                        And TBRAPPL_REAPPL_IND is null )  loop
                                                                                
                                        gb_common.p_set_context('TB_RECEIVABLE','PROCESS','APPLPMNT-FORCE','N');

                                       tv_application.p_unapply_by_tran_number( p_pidm               => pagoppl.TBRAPPL_PIDM,
                                                                                                      p_pay_tran_number    => pagoppl.TBRAPPL_PAY_TRAN_NUMBER,
                                                                                                      p_unapply_direct_pay => pagoppl.TBRAPPL_DIRECT_PAY_TYPE);   
                                                                                                                                              
                                                                               
                                      -- dbms_output.put_line('pidm:' ||pagoppl.TBRAPPL_PIDM||'pay_tran:'|| pagoppl.TBRAPPL_PAY_TRAN_NUMBER||' '||'chg_tran:'||  pagoppl.TBRAPPL_CHG_TRAN_NUMBER);                                              
                                                                                
                    End Loop pagoppl;
                                                        -- dbms_output.put_line('cancela - pago y actualiza varias tablas ');
                    
                    Begin 
                             select tbraccd_amount into monto_origen from tbraccd
                             where tbraccd_pidm=v_pidm
                             and     tbraccd_tran_number=tran_origen;
                             
                    Exception when others then
                        v_error := 'Error al recuperar el monto 5.1'||' := ' ||sqlerrm;
                        Open cur for select null, null, null, v_error from dual;
                        RETURN (cur);
                    End;

                                                   
                         --********CLONANDO EL REGISTRO CON TBRACCD_AMOUNT NEGATIVO Y TBRACCD_BALANCE = 0 **************--
                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                            into v_tran_cancela 
                        FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm;
                                        
                       begin
                        SELECT  tbbdetc_desc into desc_detl1
                        from tbbdetc
                        where cod_det1=tbbdetc_detail_code;
                        exception when others then
                        --dbms_output.put_line( 'No existe código detalle:');
                        v_error :=  'No existe código detalle 5.1:'||cod_det1;
                       open cur for select null, null, null, 'No existe código detalle 5.1:'||cod_det1 from dual;
                                 RETURN (cur);
                       end;  
                       
                        begin
                        SELECT  tbbdetc_desc into desc_detl2
                        from tbbdetc
                        where cod_det2=tbbdetc_detail_code;
                        exception when others then
                        --dbms_output.put_line( 'No existe código detalle:');
                        v_error := 'No existe código detalle 5.1:'||cod_det2;
                       open cur for select null, null, null, 'No existe código detalle 5.1:'||cod_det2 from dual;
                                 RETURN (cur);
                       end; 
                       
                       Begin 
                                        INSERT INTO TBRACCD
                                        (TBRACCD_PIDM
                                        ,TBRACCD_TRAN_NUMBER
                                        ,TBRACCD_TERM_CODE
                                        ,TBRACCD_DETAIL_CODE
                                        ,TBRACCD_USER
                                        ,TBRACCD_ENTRY_DATE
                                        ,TBRACCD_AMOUNT
                                        ,TBRACCD_BALANCE
                                        ,TBRACCD_EFFECTIVE_DATE
                                        ,TBRACCD_TRAN_NUMBER_PAID
                                        ,TBRACCD_DESC
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,TBRACCD_PAYMENT_ID
                                        ,TBRACCD_DOCUMENT_NUMBER
                                        ,TBRACCD_ACTIVITY_DATE
                                        ,TBRACCD_SESSION_NUMBER
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,TBRACCD_PERIOD
                                        ,TBRACCD_TRANS_DATE
                                        ,TBRACCD_FOREIGN_AMOUNT
                                        )
                                        SELECT 
                                        TBRACCD_PIDM
                                        ,v_tran_cancela
                                        ,TBRACCD_TERM_CODE
                                        ,cod_det1
                                        ,'POLIZAS'
                                        ,SYSDATE
                                        ,TBRACCD_AMOUNT  *-1
                                        ,0
                                        ,SYSDATE --DEBERA SER LA FECHA EN QUE SE POSTEO LA POLIZA
                                        ,tran_origen
                                        ,desc_detl1
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,num_pago
                                        ,num_docto
                                        ,SYSDATE
                                        ,0
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,folio
                                        ,TBRACCD_TRANS_DATE
                                        ,1
                                        FROM TBRACCD
                                        WHERE TBRACCD_PIDM =  v_pidm 
                                        AND TBRACCD_TRAN_NUMBER =tran_origen;-- '30535'
                        exception when others then
                        --dbms_output.put_line( 'No existe código detalle:');
                        v_error := 'Se presento un error al insertar tbraccd 5.1:'||sqlerrm;
                       open cur for select null, null, null, v_error from dual;
                                 RETURN (cur);
                       end; 
                                        
                                        
                                        
                --dbms_output.put_line('1 v_pidm:'|| v_pidm||' '||'v_tran_cancela:'|| v_tran_cancela||' '||'texto:'|| texto);            
             
                     Begin
                              v_error_transfer:=pkg_simoba.sp_reference( v_pidm, v_tran_cancela, texto);
                              
                               If v_error_transfer !=  'EXITO' then 
                                   v_error := 'Se presento un error al insertar text 5.1'||v_error_transfer;
                               End if;
                              
                              
                     exception when others then
                       --dbms_output.put_line( 'No existe código detalle:');
                      v_error := 'Se presento un error al insertar text 5.1:'||sqlerrm;
                     open cur for select null, null, null, v_error from dual;
                             RETURN (cur);
                     end; 
                              

                             --dbms_output.put_line('inserta registro cancela');
                     Begin       
                             update  tbraccd set tbraccd_balance=0
                             where tbraccd_pidm=v_pidm
                             and     tbraccd_tran_number=tran_origen;
                     exception when others then
                       --dbms_output.put_line( 'No existe código detalle:');
                      v_error := 'Se presento un error al actualizar tbraccd 5.1:'||sqlerrm;
                     open cur for select null, null, null, v_error from dual;
                             RETURN (cur);
                     end; 
                             
                     Begin                                                                                                                        
                             Update TVRACCD
                             set TVRACCD_BALANCE = 0
                             Where TVRACCD_PIDM = v_pidm
                             And TVRACCD_ACCD_TRAN_NUMBER = tran_origen;      
                     Exception   
                     When Others  then
                      v_error :=  'Se presento un error al actualizar TVRACCD 5.1:'||sqlerrm;
                     open cur for select null, null, null,v_error from dual;
                             RETURN (cur);
                     end; 
                                                                                   


                    Begin
                            select to_char(tbraccd_trans_date,'dd/mm/rrrr') 
                                into f_tran
                            from tbraccd
                            where tbraccd_pidm = v_pidm --
                            and     tbraccd_tran_number=tran_origen; 
                    Exception
                    When Others  then 
                      v_error :=  'Se presento un error al actualizar TVRACCD 5.1:'||sqlerrm;
                     open cur for select null, null, null,v_error from dual;
                             RETURN (cur);
                    end;                             

                    periodo:= fget_periodo_general(substr(id_destino,1,2),f_tran) ;   

                
                            --********REALIZANDO LA TRANSFERENCIA**************--
                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 
                            into v_tran_transfiere 
                        FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm_dest;
                        
                    Begin
                        
                           INSERT INTO TBRACCD
                                    (TBRACCD_PIDM
                                    ,TBRACCD_TRAN_NUMBER
                                    ,TBRACCD_TERM_CODE
                                    ,TBRACCD_DETAIL_CODE
                                    ,TBRACCD_USER
                                    ,TBRACCD_ENTRY_DATE
                                    ,TBRACCD_AMOUNT
                                    ,TBRACCD_BALANCE
                                    ,TBRACCD_EFFECTIVE_DATE
                                    ,TBRACCD_DESC
                                    ,TBRACCD_CROSSREF_DETAIL_CODE
                                    ,TBRACCD_SRCE_CODE
                                    ,TBRACCD_ACCT_FEED_IND
                                    ,TBRACCD_ACTIVITY_DATE
                                    ,TBRACCD_SESSION_NUMBER
                                    ,TBRACCD_TRANS_DATE
                                    ,TBRACCD_PAYMENT_ID
                                    ,TBRACCD_DOCUMENT_NUMBER
                                    ,TBRACCD_CURR_CODE
                                    ,TBRACCD_DATA_ORIGIN
                                    ,TBRACCD_CREATE_SOURCE
                                    ,TBRACCD_SURROGATE_ID
                                    ,TBRACCD_VERSION
                                    ,TBRACCD_PERIOD
                                    ,TBRACCD_FOREIGN_AMOUNT
                                    )
                                    SELECT 
                                     v_pidm_dest 
                                    ,v_tran_transfiere
                                    ,periodo
                                    ,cod_det2
                                    ,'POLIZAS'
                                    ,SYSDATE
                                    ,TBRACCD_AMOUNT
                                    ,TBRACCD_AMOUNT *-1
                                    ,SYSDATE --DEBERA SER LA FECHA EN QUE SE POSTEO LA POLIZA--
                                    ,desc_detl2
                                    ,TBRACCD_CROSSREF_DETAIL_CODE
                                    ,TBRACCD_SRCE_CODE
                                    ,TBRACCD_ACCT_FEED_IND
                                    ,SYSDATE
                                    ,TBRACCD_SESSION_NUMBER
                                    ,TBRACCD_TRANS_DATE
                                    ,num_pago
                                    ,num_docto
                                    ,TBRACCD_CURR_CODE
                                    ,TBRACCD_DATA_ORIGIN
                                    ,TBRACCD_CREATE_SOURCE
                                    ,TBRACCD_SURROGATE_ID
                                    ,TBRACCD_VERSION
                                    ,folio
                                    ,2
                                    FROM TBRACCD
                                    WHERE TBRACCD_PIDM = v_pidm 
                                    AND TBRACCD_TRAN_NUMBER = tran_origen;--'30535'      
                                    
                    Exception    
                    When Others then   
                      v_error := 'Se presento un error al insertar Tbraccd 5.2: '||sqlerrm;
                     open cur for select null, null, null, v_error from dual;
                             RETURN (cur);
                    End; 
                                    
                                    
                  --dbms_output.put_line('3 v_pidm_dest:'|| v_pidm_dest||' '||'v_tran_transfiere:'|| v_tran_transfiere||' '||'texto:'|| texto);  
                    Begin
                            v_error_transfer:=pkg_simoba.sp_reference( v_pidm_dest, v_tran_transfiere, texto);
                            
                            If v_error_transfer !=  'EXITO' then 
                               v_error := 'Error al Insertar Texto bloque3.1 '||v_error_transfer;
                            End if;

                    Exception        
                      --v_error := sqlerrm;
                      When Others then 
                     open cur for select null, null, null, 'Se presento un error al insertar Texto 5.2:'||v_error_transfer from dual;
                             RETURN (cur);
                    End; 
                            
                                    
                                   
                        --***********************INSERTANDO  EN  LA  TABLA  BITACORA CANCELACION************************--
                        Begin
                                INSERT INTO TBITANI
                                (
                                TBITANI_FOLIO
                                ,TBITANI_TIPO_POLIZA
                                ,TBITANI_PIDM_ORIGEN 
                                ,TBITANI_MONTO_ORIGEN
                                ,TBITANI_TRAN_NUMBER_ORIGEN
                                ,TBITANI_TRAN_NUMBER_CANCELA
                                ,TBITANI_FECHA_TRAN
                                ,TBITANI_PIDM_DESTINO --(p_matricula)
                                ,TBITANI_TRAN_NUMBER_DESTINO
                                ,TBITANI_MONTO_DESINO
                                ,TBITANI_ACTIVITY_DATE
                                ,TBITANI_PROCESO_ID
                                )
                                SELECT
                                folio,
                                'RI',
                                v_pidm --PIDM ORIGEN--
                                ,monto_origen --MONTO ORIGEN--
                                ,tran_origen --TBRACCD_TRAN_NUMBER ORIGEN--
                                ,v_tran_cancela -- Transacción que cancela
                                ,TBRACCD_ENTRY_DATE -- FECHA DE TRANSACCION--
                                ,v_pidm_dest --PIDM DESTINO--
                                ,v_tran_transfiere
                                ,monto_origen --MONTO DESTINO
                                ,SYSDATE --FECHA DEL SISTEMA--
                                ,(select nvl(max(tbitani_proceso_id),0)+1 from tbitani
                                   where tbitani_folio=folio) --ID DEPROCESO (NO IDENTIFICADOS
                                            FROM TBRACCD
                                            WHERE TBRACCD_PIDM = v_pidm 
                                            AND TBRACCD_TRAN_NUMBER = tran_origen;
                        Exception        
                        When Others then  
                          v_error :=  'Se presento un error al insertar TBITANI 5.3:'||sqlerrm;
                         open cur for select null, null, null,v_error from dual;
                                 RETURN (cur);
                        End; 

  
                                            
                        COMMIT;
    --                     dbms_output.put_line('inserta registro bitacora');
      
                         If v_error is null then       
                                               v_error:='Proceso exitoso';
                                               open cur for select a.spriden_id, tbitani_tran_number_cancela, b.spriden_id, tbitani_tran_number_destino
                                                                   from tbitani, spriden a, spriden b
                                                                   where tbitani_pidm_origen=a.spriden_pidm
                                                                   and     tbitani_pidm_destino=b.spriden_pidm
                                                                   and     tbitani_folio=folio;
                                                RETURN (cur);           
                         Else
                               open cur for select null, null, null,  v_error from dual;
                                         RETURN (cur);
                                 --return(v_error );
                          End if;    
                                                                                                                       

    Exception
    When Others then 
    dbms_output.put_line('error:'||sqlerrm);
    v_error:='ERROR PKG_TRANSFERENCIA: ' || SQLERRM;
    open cur for select null, null, null,v_error  from dual;
                    RETURN (cur);
    End;

End REASIG_CAMP;   


function REV_REASIG_DIV(folio_origen varchar2, folio_destino varchar2,num_pago in varchar2, num_docto in varchar2, texto in varchar2)  RETURN  PKG_TRANSFERENCIA.products_type
IS
v_tran_cancela number;
v_tran_diferencia number;
pidm_origen        number;
tran_origen         number;
total                    number;
importe            number;
ptex3               varchar2(4000);
v_error_transfer varchar2(4000);
v_error varchar2(4000);  

cur pkg_transferencia.products_type;

begin

            v_error := null;

            For c in (select tbitani_pidm_destino pidm, tbitani_tran_number_destino tran, tbitani_monto_desino monto, tbitani_pidm_origen pidm_origen, tbitani_monto_origen monto_origen, 
                                   tbitani_tran_number_origen tran_origen from tbitani
                         where tbitani_folio=folio_origen) loop

                                                 For pagoppl in (select TBRAPPL_PIDM, TBRAPPL_PAY_TRAN_NUMBER, TBRAPPL_CHG_TRAN_NUMBER, TBRAPPL_AMOUNT, TBRAPPL_DIRECT_PAY_TYPE
                                                                        from tbrappl 
                                                                        Where TBRAPPL_PIDM =c.pidm
                                                                        And TBRAPPL_PAY_TRAN_NUMBER =c.tran
                                                                        And TBRAPPL_REAPPL_IND is null )  loop
                                                                        gb_common.p_set_context('TB_RECEIVABLE','PROCESS','APPLPMNT-FORCE','N');

                                                                       tv_application.p_unapply_by_tran_number( p_pidm               => pagoppl.TBRAPPL_PIDM,
                                                                                                                                      p_pay_tran_number    => pagoppl.TBRAPPL_PAY_TRAN_NUMBER,
                                                                                                                                      p_unapply_direct_pay => pagoppl.TBRAPPL_DIRECT_PAY_TYPE);   

                                                                       --dbms_output.put_line('pidm:' ||pagoppl.TBRAPPL_PIDM||'pay_tran:'|| pagoppl.TBRAPPL_PAY_TRAN_NUMBER||' '||'chg_tran:'||  pagoppl.TBRAPPL_CHG_TRAN_NUMBER);                                              
                                                                        
                                                  End Loop pagoppl;

                                                  Begin
                                                  
                                                            SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 into v_tran_cancela FROM TBRACCD WHERE TBRACCD_PIDM = c.pidm;
                                                            INSERT INTO TBRACCD
                                                            (TBRACCD_PIDM
                                                            ,TBRACCD_TRAN_NUMBER
                                                            ,TBRACCD_TERM_CODE
                                                            ,TBRACCD_DETAIL_CODE
                                                            ,TBRACCD_USER
                                                            ,TBRACCD_ENTRY_DATE
                                                            ,TBRACCD_AMOUNT
                                                            ,TBRACCD_BALANCE
                                                            ,TBRACCD_EFFECTIVE_DATE
                                                            ,TBRACCD_TRAN_NUMBER_PAID
                                                            ,TBRACCD_DESC
                                                            ,TBRACCD_CROSSREF_DETAIL_CODE
                                                            ,TBRACCD_SRCE_CODE
                                                            ,TBRACCD_ACCT_FEED_IND
                                                            ,TBRACCD_PAYMENT_ID
                                                            ,TBRACCD_DOCUMENT_NUMBER
                                                            ,TBRACCD_ACTIVITY_DATE
                                                            ,TBRACCD_SESSION_NUMBER
                                                            ,TBRACCD_CURR_CODE
                                                            ,TBRACCD_DATA_ORIGIN
                                                            ,TBRACCD_CREATE_SOURCE
                                                            ,TBRACCD_PERIOD
                                                            ,TBRACCD_TRANS_DATE
                                                            ,TBRACCD_FOREIGN_AMOUNT
                                                            )
                                                            SELECT 
                                                            TBRACCD_PIDM
                                                            ,v_tran_cancela
                                                            ,TBRACCD_TERM_CODE
                                                            ,TBRACCD_DETAIL_CODE
                                                            ,'POLIZAS'
                                                            ,SYSDATE
                                                            ,TBRACCD_AMOUNT   *-1
                                                            ,0
                                                            ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL POSTEO--
                                                            ,c.tran
                                                            ,TBRACCD_DESC
                                                            ,TBRACCD_CROSSREF_DETAIL_CODE
                                                            ,TBRACCD_SRCE_CODE
                                                            ,TBRACCD_ACCT_FEED_IND
                                                            ,num_pago
                                                            ,num_docto    
                                                            ,SYSDATE
                                                            ,0
                                                            ,TBRACCD_CURR_CODE
                                                            ,TBRACCD_DATA_ORIGIN
                                                            ,TBRACCD_CREATE_SOURCE
                                                            ,folio_destino
                                                            ,TBRACCD_TRANS_DATE
                                                            ,1
                                                            FROM TBRACCD
                                                            WHERE TBRACCD_PIDM =  c.pidm 
                                                            AND TBRACCD_TRAN_NUMBER =c.tran;
                                                  Exception    
                                                  When Others then      
                                                      v_error := 'Se presento un error al insertar Tbraccd 6.1:'||sqlerrm;
                                                   open cur for select null, null, null, v_error from dual;
                                                      RETURN (cur);
                                                  End; 
                                                    
                                                  Begin  

                                                        v_error_transfer:=pkg_simoba.sp_reference( c.pidm, v_tran_cancela, texto); 
                                                           If v_error_transfer !=  'EXITO' then 
                                                               v_error := 'Se presento un error al insertar Tbraccd 6.1 '||v_error_transfer;
                                                            End if;
                                                        
                                                  Exception     
                                                  When Others then     
                                                      --v_error := sqlerrm;
                                                   open cur for select null, null, null, 'Se presento un error al insertar Tbraccd 6.1:'||v_error_transfer from dual;
                                                      RETURN (cur);
                                                  End; 
                   
                                                  Begin
                                                         update  tbraccd set tbraccd_balance=0
                                                         where tbraccd_pidm=c.pidm
                                                         and     tbraccd_tran_number=c.tran;
                                                  Exception 
                                                       When Others then           
                                                      v_error := 'Se presento un error al actualizar Tbraccd 6.1:'||sqlerrm;
                                                   open cur for select null, null, null, v_error from dual;
                                                      RETURN (cur);
                                                  End; 

                                                 Begin                                                                                                                 
                                                         Update TVRACCD
                                                         set TVRACCD_BALANCE = 0
                                                         Where TVRACCD_PIDM = c.pidm
                                                         And TVRACCD_ACCD_TRAN_NUMBER = c.tran;       
                                                 Exception    
                                                 When Others then      
                                                      v_error := 'Se presento un error al actualizar TVRACCD 6.1:'||sqlerrm;
                                                   open cur for select null, null, null, v_error from dual;
                                                      RETURN (cur);
                                                 End; 
                                         
                                                 Begin                                             

                                                        INSERT INTO TBITANI
                                                        (
                                                        TBITANI_FOLIO
                                                        ,TBITANI_TIPO_POLIZA
                                                        ,TBITANI_PIDM_ORIGEN 
                                                        ,TBITANI_MONTO_ORIGEN
                                                        ,TBITANI_TRAN_NUMBER_ORIGEN
                                                        ,TBITANI_TRAN_NUMBER_CANCELA
                                                        ,TBITANI_FECHA_TRAN
                                                        ,TBITANI_PIDM_DESTINO --(p_matricula)
                                                        ,TBITANI_TRAN_NUMBER_DESTINO
                                                        ,TBITANI_MONTO_DESINO
                                                        ,TBITANI_ACTIVITY_DATE
                                                        ,TBITANI_PROCESO_ID
                                                        )
                                                        values (
                                                        folio_destino,
                                                        'TD',
                                                        c.pidm --PIDM ORIGEN--
                                                        ,c.monto --MONTO ORIGEN--
                                                        ,c.tran --TBRACCD_TRAN_NUMBER ORIGEN--
                                                        ,v_tran_cancela -- Transacción que cancela
                                                        ,sysdate -- FECHA DE TRANSACCION--
                                                        ,c.pidm_origen --PIDM DESTINO--
                                                        ,0
                                                        ,c.monto_origen --MONTO DESTINO
                                                        ,SYSDATE --FECHA DEL SISTEMA--
                                                        ,(select nvl(max(tbitani_proceso_id),0)+1 from tbitani
                                                          where tbitani_folio=folio_destino));
                                                 Exception    
                                                 When Others then      
                                                      v_error := 'Se presento un error al insertar TBITANI 6.1:'||sqlerrm;
                                                   open cur for select null, null, null, v_error from dual;
                                                      RETURN (cur);
                                                  End; 

                                                                                                               
            end loop;

            commit;

            Begin
                select distinct tbitani_pidm_origen, tbitani_monto_origen , tbitani_tran_number_cancela
                into pidm_origen, total, tran_origen
                from tbitani
                where tbitani_folio=folio_origen;
            Exception    
            When Others then      
                  v_error := 'Se presento un error al consultar TBITANI 6.1:'||sqlerrm;
               open cur for select null, null, null, v_error from dual;
                  RETURN (cur);
             End; 
                
                   SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 into v_tran_diferencia 
                    FROM TBRACCD WHERE TBRACCD_PIDM = pidm_origen;
                                        
             Begin
                   INSERT INTO TBRACCD
                    (TBRACCD_PIDM
                    ,TBRACCD_TRAN_NUMBER
                    ,TBRACCD_TERM_CODE
                    ,TBRACCD_DETAIL_CODE
                    ,TBRACCD_USER
                    ,TBRACCD_ENTRY_DATE
                    ,TBRACCD_AMOUNT
                    ,TBRACCD_BALANCE
                    ,TBRACCD_EFFECTIVE_DATE
                    ,TBRACCD_TRAN_NUMBER_PAID
                    ,TBRACCD_DESC
                    ,TBRACCD_CROSSREF_DETAIL_CODE
                    ,TBRACCD_SRCE_CODE
                    ,TBRACCD_ACCT_FEED_IND
                    ,TBRACCD_ACTIVITY_DATE
                    ,TBRACCD_SESSION_NUMBER
                    ,TBRACCD_CURR_CODE
                    ,TBRACCD_DATA_ORIGIN
                    ,TBRACCD_CREATE_SOURCE
                    ,TBRACCD_SURROGATE_ID
                    ,TBRACCD_VERSION
                    ,TBRACCD_PERIOD
                    ,TBRACCD_TRANS_DATE
                    ,TBRACCD_PAYMENT_ID       
                    ,TBRACCD_DOCUMENT_NUMBER  
                    )
                    SELECT 
                    TBRACCD_PIDM
                    , v_tran_diferencia
                    ,TBRACCD_TERM_CODE
                    ,TBRACCD_DETAIL_CODE
                    ,'POLIZAS'
                    ,SYSDATE
                    ,total
                    ,total *-1
                    ,SYSDATE --DEBERA SER LA FECHA EN QUE SE HIZO EL POSTEO--
                    ,null
                    ,TBRACCD_DESC
                    ,TBRACCD_CROSSREF_DETAIL_CODE
                    ,TBRACCD_SRCE_CODE
                    ,TBRACCD_ACCT_FEED_IND
                    ,SYSDATE
                    ,0
                    ,TBRACCD_CURR_CODE
                    ,TBRACCD_DATA_ORIGIN
                    ,TBRACCD_CREATE_SOURCE
                    ,TBRACCD_SURROGATE_ID
                    ,TBRACCD_VERSION
                    ,folio_destino
                    ,TBRACCD_TRANS_DATE
                    ,num_pago
                    ,num_docto   
                    FROM TBRACCD
                    WHERE TBRACCD_PIDM = pidm_origen 
                    AND TBRACCD_TRAN_NUMBER = tran_origen;
             Exception
             When Others then      
                  v_error := 'Se presento un error al insertar Tbraccd 6.2:'||sqlerrm;
               open cur for select null, null, null, v_error from dual;
                  RETURN (cur);
             End; 
 
            Begin
                   v_error_transfer:=pkg_simoba.sp_reference( pidm_origen, v_tran_diferencia, texto);
                        If v_error_transfer !=  'EXITO' then 
                           v_error := 'Se presento un error al insertar Tbraccd 6. '||v_error_transfer;
                        End if;
                   
                   
            Exception
            When Others then      
                 -- v_error := sqlerrm;
               open cur for select null, null, null, 'Se presento un error al insertar Tbraccd 6.2:'||v_error_transfer from dual;
                  RETURN (cur);
            End; 
                   
            Begin
                     update tbitani set tbitani_tran_number_destino=v_tran_diferencia
                     where tbitani_folio=folio_destino;
                     commit;
            Exception
            When Others then      
                 v_error := 'Se presento un error al actualizar tbitani 6.2:'||sqlerrm;
               open cur for select null, null, null, v_error from dual;
                  RETURN (cur);
             End; 


            
              If v_error is null then       
                                   v_error:='Proceso exitoso';
                 open cur for select a.spriden_id, tbitani_tran_number_cancela, b.spriden_id, tbitani_tran_number_destino
                               from tbitani, spriden a, spriden b
                               where tbitani_pidm_origen=a.spriden_pidm
                               and     tbitani_pidm_destino=b.spriden_pidm
                               and     tbitani_folio=folio_destino;
                                    RETURN (cur);           
             Else
                   open cur for select null, null, null,  v_error from dual;
                             RETURN (cur);
                     --return(v_error );
              End if;    
            
            
            
            
            
            
            

end REV_REASIG_DIV;
   
function  CARGO_CXP (id_origen IN VARCHAR2,  monto in number,cod_detalle IN  varchar2 )  
RETURN  PKG_TRANSFERENCIA.products_type  
  IS 

v_pidm number;
conta    number;
v_error    varchar2(200);
v_tran_cancela number;
descrip    varchar2(30);

cur pkg_transferencia.products_type;

begin
        v_error := null;

           begin
           select spriden_pidm into v_pidm 
           from spriden
           where spriden_id=id_origen
           and     spriden_change_ind is null; --:= fget_pidm (p_cuenta);
           exception when others then
           --dbms_output.put_line('No existe estudiante/cuenta:'||id_origen);
           v_error := 'No existe estudiante/cuenta:'||id_origen;
           open cur for select null, null, null, 'No existe estudiante/cuenta:'||id_origen from dual;
                     RETURN (cur);
           end;
           --dbms_output.put_line('v_pidm:'||v_pidm);

 
    Begin
                             begin     
                             select tbbdetc_desc into descrip from tbbdetc
                             where tbbdetc_detail_code=cod_detalle;
                             exception when others then
                             descrip:=null;
                             end;                                     
                            
                             Begin
                                     --********CLONANDO EL REGISTRO CON TBRACCD_AMOUNT NEGATIVO Y TBRACCD_BALANCE = 0 **************--
                                        SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0) +1 into v_tran_cancela FROM TBRACCD WHERE TBRACCD_PIDM = v_pidm;
                                        INSERT INTO TBRACCD
                                        (TBRACCD_PIDM
                                        ,TBRACCD_TRAN_NUMBER
                                        ,TBRACCD_TERM_CODE
                                        ,TBRACCD_DETAIL_CODE
                                        ,TBRACCD_USER
                                        ,TBRACCD_ENTRY_DATE
                                        ,TBRACCD_AMOUNT
                                        ,TBRACCD_BALANCE
                                        ,TBRACCD_EFFECTIVE_DATE
                                        ,TBRACCD_TRAN_NUMBER_PAID
                                        ,TBRACCD_DESC
                                        ,TBRACCD_CROSSREF_DETAIL_CODE
                                        ,TBRACCD_SRCE_CODE
                                        ,TBRACCD_ACCT_FEED_IND
                                        ,TBRACCD_PAYMENT_ID
                                        ,TBRACCD_DOCUMENT_NUMBER
                                        ,TBRACCD_ACTIVITY_DATE
                                        ,TBRACCD_SESSION_NUMBER
                                        ,TBRACCD_CURR_CODE
                                        ,TBRACCD_DATA_ORIGIN
                                        ,TBRACCD_CREATE_SOURCE
                                        ,TBRACCD_PERIOD
                                        ,TBRACCD_TRANS_DATE
                                        ,TBRACCD_FOREIGN_AMOUNT
                                        )
                                        Values
                                        (v_pidm
                                        ,v_tran_cancela
                                        ,'000000'
                                        ,cod_detalle
                                        ,'POLIZAS'
                                        ,sysdate
                                        ,monto  -- *-1
                                        ,0
                                        ,SYSDATE --DEBE SER LA FECHA EN QUE SE HIZO EL PAGO TRANSACCION--
                                        ,null
                                        ,descrip
                                        ,null
                                        ,'T'
                                        ,'Y'
                                        ,null
                                        ,null
                                        ,SYSDATE
                                        ,0
                                        ,null
                                        ,'UTEL'
                                        ,'BANCOS'
                                        ,NULL
                                        ,SYSDATE
                                        ,1);
                                        
                             Exception
                             When Others then      
                                 v_error := 'Se presento un error al insertar  tbraccd 7.1:'||sqlerrm;
                               open cur for select null, null, null, v_error from dual;
                                  RETURN (cur);
                             End; 
                                        
                                                      

                            COMMIT;
                         --dbms_output.put_line('inserta registro cargo a cxp');
                                v_error:='Proceso exitoso';
                               open cur for select id_origen, v_tran_cancela, null, null
                                                   from dual;
                                RETURN (cur);           
                                                                                                                       
       
    
              If v_error is null then       
                                   v_error:='Proceso exitoso';
                                   open cur for select id_origen, v_tran_cancela, null, null
                                                   from dual;
                                RETURN (cur);            
             Else
                   open cur for select null, null, null,  v_error from dual;
                             RETURN (cur);
                     --return(v_error );
              End if;    
    
    

    Exception
    When Others then 
    dbms_output.put_line('error:'||sqlerrm);
    v_error:='ERROR PKG_TRANSFERENCIA: ' || SQLERRM;
    open cur for select null, null, null,v_error  from dual;
                    RETURN (cur);
    End;

End CARGO_CXP;  

END PKG_TRANSFERENCIA;
/

DROP PUBLIC SYNONYM PKG_TRANSFERENCIA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_TRANSFERENCIA FOR BANINST1.PKG_TRANSFERENCIA;


GRANT EXECUTE ON BANINST1.PKG_TRANSFERENCIA TO CONSULTA;
