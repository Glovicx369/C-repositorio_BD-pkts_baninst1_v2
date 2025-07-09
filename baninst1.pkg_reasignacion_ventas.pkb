DROP PACKAGE BODY BANINST1.PKG_REASIGNACION_VENTAS;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_reasignacion_ventas is 

FUNCTION f_inserta_tzcamb(p_pidm in varchar2, p_pidm_1 in varchar2, p_fecha in date, p_canal in varchar2, p_obs in varchar2, p_fecha_pago in date, p_monto_pago in varchar2) return Varchar2
/*
p_pidm: PIDM del alumno
p_pidm_1: PIDM del vendedor origen
p_fecha: Fecha en que se realizó la venta
p_canal: Canal que realizó la venta
p_obs: Comentarios agrregadospor el susuario
p_fecha_pago: Fecha real del pago
p_monto_pago:Monto real del pago

*/
    AS               
            vl_maximo number :=0;
            vl_error varchar2(30):='Exito';
           BEGIN
                begin
                    select nvl(max(TZCAMB_SEQUENCE),0)+1
                    into vl_maximo
                    from TZCAMB 
                    where TZCAMB_PIDM = p_pidm;
                exception
                when others then
                vl_maximo:=1;     
                end; 
                
                begin
                    insert into tzcamb
                    values(p_pidm, p_pidm_1, null,p_fecha, p_canal, null, null, p_obs ,p_fecha, p_monto_pago,null,null,null,null,null,user, sysdate,vl_maximo);
                END;
                commit;
                return vl_error;    
        EXCEPTION
        WHEN OTHERS THEN 
        vl_error:='Error'||sqlerrm;
        RETURN vl_error;
        END f_inserta_tzcamb;

                              
            
END; --ULTIMO END
/

DROP PUBLIC SYNONYM PKG_REASIGNACION_VENTAS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_REASIGNACION_VENTAS FOR BANINST1.PKG_REASIGNACION_VENTAS;
