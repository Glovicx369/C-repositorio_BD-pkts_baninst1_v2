DROP PACKAGE BODY BANINST1.PKG_INCONC_UPSELLING;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_INCONC_UPSELLING AS
/******************************************************************************
   NAME:       PKG_INCONC_UPSELLING
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        03/11/2023      vramirlo       1. Created this package body.
******************************************************************************/

Procedure  Actualiza_Padre IS

vl_variable varchar2(250)null; 

  BEGIN
    
        For cx in (
  
                    Select *
                    from TZTCONTACT  
                    Where 1=1
                    And TZTCONTACT_INCONCERT is not null
                    And TZTCONTACT_PIDM is not null
                    And TZTCONTACT_ESTATUS in (1)
                    And tipo ='CORE'
                    
                  ) loop
                  
                       ------------------ Nombre ---------------------
                        vl_variable:= null;
  
                        Begin 
                          Select distinct SPRIDEN_FIRST_NAME
                            Into vl_variable
                          from spriden
                          Where 1=1
                          And spriden_pidm  = cx.TZTCONTACT_PIDM
                          And spriden_change_ind is null;
                        Exception
                            When Others then 
                              vl_variable:= null;
                        End;
                  
                         
                   dbms_output.put_line('Nombre: '||vl_variable ||'*'||cx.TZTCONTACT_NOMBRE);
                        If vl_variable is not null and vl_variable != cx.TZTCONTACT_NOMBRE 
                        Or vl_variable is not null and vl_variable is not null and cx.TZTCONTACT_NOMBRE is null
                        then
                           
                            Begin 
                                Update TZTCONTACT
                                set TZTCONTACT_NOMBRE = vl_variable, 
                                    TZTCONTACT_ESTATUS = 2,
                                    TZTCONTACT_OBSERVACIONES = 'Se actualizo el nombre del alumno'
                                Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                                And TZTCONTACT_INCONCERT = cx.TZTCONTACT_INCONCERT;
                            Exception 
                                When Others then 
                                     dbms_output.put_line('Nombre: '||sqlerrm);
                            End;
                        End if;
  
                       ------------------ Apellido ---------------------
                        vl_variable:= null;
  
                        Begin 
                          Select distinct trim (substr (b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME,'/')-1)) ||' '|| trim (substr (b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME,'/')+1,150)) apellidos
                           Into vl_variable
                          from spriden b 
                          Where 1=1
                          And spriden_pidm  = cx.TZTCONTACT_PIDM
                          And spriden_change_ind is null;
                        Exception
                            When Others then 
                              vl_variable:= null;
                        End;
                    
                        
                   dbms_output.put_line('Apellido: '||vl_variable ||'*'||cx.TZTCONTACT_APELLIDOS);
                        If vl_variable is not null and vl_variable != cx.TZTCONTACT_APELLIDOS 
                        Or vl_variable is not null and vl_variable is not null and cx.TZTCONTACT_APELLIDOS is null
                        then 
                         
                            Begin 
                                Update TZTCONTACT
                                set TZTCONTACT_APELLIDOS = vl_variable, 
                                    TZTCONTACT_ESTATUS = 2,
                                    TZTCONTACT_OBSERVACIONES = 'Se actualizo el Apellido del alumno'
                                Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                                And TZTCONTACT_INCONCERT = cx.TZTCONTACT_INCONCERT;
                            Exception 
                                When Others then 
                                     dbms_output.put_line('Apellido: '||sqlerrm);
                            End;
                        End if;


                       ------------------ Correo ---------------------
                        vl_variable:= null;
  
                        Begin 
                        Select nvl (trim (pkg_utilerias.f_correo(a.spriden_pidm, 'PRIN')), 
                               nvl (trim (pkg_utilerias.f_correo(a.spriden_pidm, 'UCAM')),
                               trim (pkg_utilerias.f_correo(a.spriden_pidm, 'UTLX')))) Correo_Principal
                           Into vl_variable
                          from spriden a 
                          Where 1=1
                          And spriden_pidm  = cx.TZTCONTACT_PIDM
                          And spriden_change_ind is null;     
                        Exception
                            When Others then 
                              vl_variable:= null;
                        End;
                  
                            
                        dbms_output.put_line('Correo: '||vl_variable ||'*'||cx.TZTCONTACT_EMAIL);
                        If vl_variable is not null and vl_variable != cx.TZTCONTACT_EMAIL 
                        Or vl_variable is not null and vl_variable is not null and cx.TZTCONTACT_EMAIL is null
                        then 
                           
                           Begin 
                                Update TZTCONTACT
                                set TZTCONTACT_EMAIL = vl_variable, 
                                    TZTCONTACT_ESTATUS = 2,
                                    TZTCONTACT_OBSERVACIONES = 'Se actualizo el correo del alumno'
                                Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                                And TZTCONTACT_INCONCERT = cx.TZTCONTACT_INCONCERT;
                           Exception 
                                When Others then 
                                    dbms_output.put_line('Correo: '||sqlerrm);
                           End;
                        End if;

                       ------------------ Celular ---------------------
                        vl_variable:= null;
  
                        Begin 
                            Select pkg_utilerias.f_celular(b.spriden_pidm, 'CELU') celular 
                              Into vl_variable
                            from spriden b 
                            Where 1=1
                            And spriden_pidm  = cx.TZTCONTACT_PIDM
                            And spriden_change_ind is null;    
                        Exception
                            When Others then 
                              vl_variable:= null;
                        End;
                  
                        dbms_output.put_line('Celular: '||vl_variable ||'*'||cx.TZTCONTACT_MOVIL);
                  
                        If vl_variable is not null and vl_variable != cx.TZTCONTACT_MOVIL 
                            Or vl_variable is not null and vl_variable is not null and cx.TZTCONTACT_MOVIL is null
                        then 
                           
                            Begin 
                                Update TZTCONTACT
                                set TZTCONTACT_MOVIL = vl_variable, 
                                    TZTCONTACT_ESTATUS = 2,
                                    TZTCONTACT_OBSERVACIONES = 'Se actualizo el Celular del alumno'
                                Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                                And TZTCONTACT_INCONCERT = cx.TZTCONTACT_INCONCERT;
                            Exception 
                                When Others then 
                                    dbms_output.put_line('Celular: '||sqlerrm);
                            End;
                        End if;

                       ------------------ Alterno ---------------------
                        vl_variable:= null;
  
                        Begin 
                            Select pkg_utilerias.f_celular(b.spriden_pidm, 'ALTE') celular 
                              Into vl_variable
                            from spriden b 
                            Where 1=1
                            And spriden_pidm  = cx.TZTCONTACT_PIDM
                            And spriden_change_ind is null;    
                        Exception
                            When Others then 
                              vl_variable:= null;
                        End;
                   
                       
                       dbms_output.put_line('Alterno: '||vl_variable ||'*'||cx.TZTCONTACT_ALTERNO);
                        If vl_variable is not null and vl_variable != cx.TZTCONTACT_ALTERNO 
                            Or vl_variable is not null and vl_variable is not null and cx.TZTCONTACT_ALTERNO is null
                        then 
                           
                            Begin 
                                Update TZTCONTACT
                                set TZTCONTACT_ALTERNO = vl_variable, 
                                    TZTCONTACT_ESTATUS = 2,
                                    TZTCONTACT_OBSERVACIONES = 'Se actualizo el Celular Alterno del alumno'
                                Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                                And TZTCONTACT_INCONCERT = cx.TZTCONTACT_INCONCERT;
                            Exception 
                                When Others then 
                                    dbms_output.put_line('Alterno: '||sqlerrm);
                            End;
                        End if;

                       ------------------ Genero ---------------------
                        vl_variable:= null;
  
                        Begin 
                              Select decode (pkg_utilerias.f_genero(b.spriden_pidm), 'Masculino','M', 'Femenino', 'F') Genero 
                                Into vl_variable
                              from spriden b 
                              Where 1=1
                              And spriden_pidm  = cx.TZTCONTACT_PIDM
                              And spriden_change_ind is null; 
                        Exception
                            When Others then 
                              vl_variable:= null;
                        End;
                  
                        
                        dbms_output.put_line('Genero: '||vl_variable ||'*'||cx.TZTCONTACT_GENERO);
                        If vl_variable is not null and vl_variable != cx.TZTCONTACT_GENERO 
                           Or vl_variable is not null and vl_variable is not null and cx.TZTCONTACT_GENERO is null
                        then 
                           dbms_output.put_line('Entro Genero: '||vl_variable ||'*'||cx.TZTCONTACT_GENERO);
                            Begin 
                                Update TZTCONTACT
                                set TZTCONTACT_GENERO = vl_variable, 
                                    TZTCONTACT_ESTATUS = 2,
                                    TZTCONTACT_OBSERVACIONES = 'Se actualizo el Genero del alumno'
                                Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                                And TZTCONTACT_INCONCERT = cx.TZTCONTACT_INCONCERT;
                            Exception 
                                When Others then 
                                    dbms_output.put_line('Genero: '||sqlerrm);
                            End;
                        End if;


                       ------------------ Estado Civil ---------------------
                        vl_variable:= null;
  
                        Begin 
                            select distinct SPBPERS_MRTL_CODE
                                Into vl_variable
                            from SPBPERS
                            where SPBPERS_PIDM = cx.TZTCONTACT_PIDM;
                        Exception
                            When Others then 
                              vl_variable:= null;
                        End;
                  
                        dbms_output.put_line('Civil: '||vl_variable ||'*'||cx.TZTCONTACT_EDO_CIVIL);
                        
                        If vl_variable is not null and vl_variable != cx.TZTCONTACT_EDO_CIVIL 
                            Or vl_variable is not null and vl_variable is not null and cx.TZTCONTACT_EDO_CIVIL is null
                        then 
                           
                            Begin 
                                Update TZTCONTACT
                                set TZTCONTACT_EDO_CIVIL = vl_variable, 
                                    TZTCONTACT_ESTATUS = 2,
                                    TZTCONTACT_OBSERVACIONES = 'Se actualizo el Estatus Civil del alumno'
                                Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                                And TZTCONTACT_INCONCERT = cx.TZTCONTACT_INCONCERT;
                            Exception 
                                When Others then 
                                   dbms_output.put_line('Civil: '||sqlerrm);
                            End;
                        End if;


                       ------------------ Fecha de Nacimiento ---------------------
                        vl_variable:= null;
  
                        Begin 
                            select distinct SPBPERS_BIRTH_DATE
                                Into vl_variable
                            from SPBPERS
                            where SPBPERS_PIDM = cx.TZTCONTACT_PIDM;
                        Exception
                            When Others then 
                              vl_variable:= null;
                        End;
                  
                        dbms_output.put_line('nacimiento: '||vl_variable ||'*'||cx.TZTCONTACT_FEC_NAC);
                        
                        If vl_variable is not null and vl_variable != cx.TZTCONTACT_FEC_NAC 
                            Or vl_variable is not null and vl_variable is not null and cx.TZTCONTACT_FEC_NAC is null
                           then 
                            
                            Begin 
                                Update TZTCONTACT
                                set TZTCONTACT_FEC_NAC = vl_variable, 
                                    TZTCONTACT_ESTATUS = 2,
                                    TZTCONTACT_OBSERVACIONES = 'Se actualizo fecha de Nacimiento del alumno'
                                Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                                And TZTCONTACT_INCONCERT = cx.TZTCONTACT_INCONCERT;
                            Exception 
                                When Others then 
                                    dbms_output.put_line('nacimiento: '||sqlerrm);
                            End;
                        End if;



         End Loop;
         Commit;
  
  
  END Actualiza_Padre;
  
  

Procedure  Actualiza_hijo IS

vl_variable varchar2(250)null;
vl_dom number:=0;
vl_nodom number:=0;
vl_fecha_cierre date;
 

  BEGIN  
  
          Begin
                Update TZTOPORT
                set TZTOPORT_FECHA_CIERRE = null
                Where 1=1
                And TZTOPORT_FECHA_CIERRE = '01/01/2050';
          Exception
            When Others then 
                null;
          End;  
          Commit;
  
  
        For cx in (
        
                        Select a.TZTCONTACT_PIDM pidm, a.TZTCONTACT_MATRICULA Matricula, b.*
                        from TZTCONTACT a  
                        join  TZTOPORT b on b.TZTCONTACT_ID = a.TZTCONTACT_ID
                        Where 1=1
                        And a.TZTCONTACT_INCONCERT is not null
                        And a.TZTCONTACT_PIDM is not null
                        And b.TZTOPORT_ESTATUS in (1)      
                        And a.tipo ='CORE'  
        
        ) loop
        
        
                  dbms_output.put_line('Inicia Proceso : '||cx.Matricula);
                  


                For cx1 in (
                
                            Select distinct tbrappl_pidm, TBRAPPL_PAY_TRAN_NUMBER
                            from tbrappl
                            where 1=1
                            And tbrappl_pidm = cx.pidm
                            and TBRAPPL_REAPPL_IND is null
                            And TBRAPPL_CHG_TRAN_NUMBER in (  Select TBRACCD_TRAN_NUMBER
                                                                from tbraccd a
                                                                Where 1=1
                                                                And a.tbraccd_pidm = cx.pidm
                                                                And a.tbraccd_detail_code = cx.TZTOPORT_SERVICIO
                                                                And a.tbraccd_amount != tbraccd_balance
                                                                And trunc (a.TBRACCD_FEED_DATE) = cx.TZTOPORT_FECHA_INI
                                                                And trunc (a.TBRACCD_EFFECTIVE_DATE) = (select min (a1.TBRACCD_EFFECTIVE_DATE)
                                                                                                        from tbraccd a1
                                                                                                        Where 1=1
                                                                                                        And a.tbraccd_pidm = a1.tbraccd_pidm
                                                                                                        And a.tbraccd_detail_code = a1.tbraccd_detail_code
                                                                                                        And trunc (a.TBRACCD_FEED_DATE) = (a1.TBRACCD_FEED_DATE) 
                                                                                                       )
                                                               )                
                ) loop
                
                    Begin
                            Select count(*)
                                Into vl_dom
                            from tbraccd
                            join TZTNCD on TZTNCD_CODE = tbraccd_detail_code and TZTNCD_CONCEPTO in ('Poliza', 'Deposito', 'Nota Distribucion')
                            where 1=1
                            And TBRACCD_DESC like '%DOM'
                            And tbraccd_pidm = cx1.tbrappl_pidm
                            And  TBRACCD_TRAN_NUMBER = cx1.TBRAPPL_PAY_TRAN_NUMBER;
                    Exception
                        When Others then 
                          vl_dom:=0;        
                    End;
                
                
                    Begin
                            Select count(*)
                                Into vl_nodom
                            from tbraccd
                            join TZTNCD on TZTNCD_CODE = tbraccd_detail_code and TZTNCD_CONCEPTO in ('Poliza', 'Deposito', 'Nota Distribucion')
                            where 1=1
                            And TBRACCD_DESC not like '%DOM'
                            And tbraccd_pidm = cx1.tbrappl_pidm
                            And  TBRACCD_TRAN_NUMBER = cx1.TBRAPPL_PAY_TRAN_NUMBER;
                    Exception
                        When Others then 
                          vl_nodom:=0;        
                    End;                
                
                
                    If vl_dom >= 1 then  --> si encuentra un monto domiciliado lo marca asi
                    
                      dbms_output.put_line('Actualiza pago Dom : '||vl_dom); 
                       
                       Begin 
                            Update TZTOPORT
                            set  TZTOPORT_METODO_PAGO = 'Pago_en_linea',
                                 TZTOPORT_ESTATUS = 2,
                                 TZTOPORT_OBSERVACIONES = 'Se actualiza el Metodo de Pago'
                            Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                            And TZTOPORT_ID = cx.TZTOPORT_ID
                            And TZTOPORT_OPORTUNIDAD = cx.TZTOPORT_OPORTUNIDAD;
                       Exception
                        When Others then 
                         null;
                       End;
                    
                    Elsif vl_dom = 0 and vl_nodom >= 1  then  --> si encuentra un monto no domiciliado lo marca asi
                      dbms_output.put_line('Actualiza pago NO_Dom : '||vl_nodom);
                    
                       Begin 
                            Update TZTOPORT
                            set  TZTOPORT_METODO_PAGO = 'Pago_referenciado',
                                 TZTOPORT_ESTATUS = 2,
                                 TZTOPORT_OBSERVACIONES = 'Se actualiza el Metodo de Pago'
                            Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                            And TZTOPORT_ID = cx.TZTOPORT_ID
                            And TZTOPORT_OPORTUNIDAD = cx.TZTOPORT_OPORTUNIDAD;
                       Exception
                        When Others then 
                         null;
                       End;                    
                    
                    
                    End if; 
                
                
                End loop cx1;
        
                vl_dom:=0;
                Begin   ------------ Valida si el alumno esta domicialiado
                
                 Select count(*)
                    into vl_dom
                 from goremal 
                 where 1=1
                 And GOREMAL_PIDM = cx.pidm
                 And GOREMAL_EMAL_CODE like 'DO%';
                Exception
                    When Others then 
                     vl_dom:=0;
                End;
        
               dbms_output.put_line('Valida Si esta Domiciliado  : '||vl_dom ||'*'||cx.TZTOPORT_DOMICILIACION);
        
                If vl_dom > 0 and cx.TZTOPORT_DOMICILIACION in (2) or cx.TZTOPORT_DOMICILIACION is null then 
                
                     dbms_output.put_line('Actualiza Si esta Domiciliado  : '||vl_dom ||'*'||cx.TZTOPORT_DOMICILIACION);

                       Begin 
                            Update TZTOPORT
                            set  TZTOPORT_DOMICILIACION = 1,
                                 TZTOPORT_ESTATUS = 2,
                                 TZTOPORT_OBSERVACIONES = 'Se actualiza la Domiciliacion'
                            Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                            And TZTOPORT_ID = cx.TZTOPORT_ID
                            And TZTOPORT_OPORTUNIDAD = cx.TZTOPORT_OPORTUNIDAD;
                       Exception
                        When Others then 
                         null;
                       End;                  
                ElsIf vl_dom = 0 and cx.TZTOPORT_DOMICILIACION in (1) or cx.TZTOPORT_DOMICILIACION is null then
                
                    dbms_output.put_line('Actualiza NO esta Domiciliado  : '||vl_dom ||'*'||cx.TZTOPORT_DOMICILIACION);
        
                       Begin 
                            Update TZTOPORT
                            set  TZTOPORT_DOMICILIACION = 2,
                                 TZTOPORT_ESTATUS = 2,
                                 TZTOPORT_OBSERVACIONES = 'Se actualiza la Domiciliacion'
                            Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                            And TZTOPORT_ID = cx.TZTOPORT_ID
                            And TZTOPORT_OPORTUNIDAD = cx.TZTOPORT_OPORTUNIDAD;
                       Exception
                        When Others then 
                         null;
                       End;              
        
                End if;
                
                ------------------------- Fecha de cierre
                 dbms_output.put_line('Llega al proceso de Cierre Pidm  : '||cx.pidm ||'servicio'||cx.TZTOPORT_SERVICIO ||'Fecha_inicio'||cx.TZTOPORT_FECHA_INI);
                
                
                For cx1 in (
                
                            Select distinct tbrappl_pidm, TBRAPPL_PAY_TRAN_NUMBER
                            from tbrappl
                            where 1=1
                            And tbrappl_pidm = cx.pidm
                            and TBRAPPL_REAPPL_IND is null
                            And TBRAPPL_CHG_TRAN_NUMBER in (  Select TBRACCD_TRAN_NUMBER
                                                                from tbraccd a
                                                                Where 1=1
                                                                And a.tbraccd_pidm = cx.pidm
                                                                And a.tbraccd_detail_code = cx.TZTOPORT_SERVICIO
                                                                And a.tbraccd_amount != tbraccd_balance
                                                                And trunc (a.TBRACCD_FEED_DATE) = cx.TZTOPORT_FECHA_INI
                                                                And trunc (a.TBRACCD_EFFECTIVE_DATE) = (select min (a1.TBRACCD_EFFECTIVE_DATE)
                                                                                                        from tbraccd a1
                                                                                                        Where 1=1
                                                                                                        And a.tbraccd_pidm = a1.tbraccd_pidm
                                                                                                        And a.tbraccd_detail_code = a1.tbraccd_detail_code
                                                                                                        And trunc (a.TBRACCD_FEED_DATE) = (a1.TBRACCD_FEED_DATE) 
                                                                                                       )
                                                               )                
                ) loop
                    
                    vl_fecha_cierre:= null;   
                    
                    dbms_output.put_line('Recupara Fecha de Cierre Parametros  : '||cx1.TBRAPPL_PAY_TRAN_NUMBER );
                
                    Begin
                            Select distinct min (TBRACCD_TRANS_DATE) 
                                Into vl_fecha_cierre
                            from tbraccd
                            join TZTNCD on TZTNCD_CODE = tbraccd_detail_code and TZTNCD_CONCEPTO in ('Poliza', 'Deposito', 'Nota Distribucion')
                            where 1=1
                            And tbraccd_pidm = cx1.tbrappl_pidm
                            And  TBRACCD_TRAN_NUMBER = cx1.TBRAPPL_PAY_TRAN_NUMBER;
                    Exception
                        When Others then 
                          vl_fecha_cierre:=null;        
                    End;
                
                    dbms_output.put_line('Fecha de Cierre Parametros   : '||vl_fecha_cierre ||'*'||cx.TZTOPORT_FECHA_CIERRE);
                
                    If (vl_fecha_cierre is not null and cx.TZTOPORT_FECHA_CIERRE != vl_fecha_cierre) 
                        or (vl_fecha_cierre is not null and cx.TZTOPORT_FECHA_CIERRE is null) 
                       then   
                       
                        dbms_output.put_line(' Entra Fecha de Cierre   : '||vl_fecha_cierre ||'*'||cx.TZTOPORT_FECHA_CIERRE);
                       
                       Begin 
                            Update TZTOPORT
                            set  TZTOPORT_FECHA_CIERRE = vl_fecha_cierre,
                                 TZTOPORT_ETAPA = 'CLOSED_WON',
                                 TZTOPORT_ESTATUS = 2,
                                 TZTOPORT_ESTADO = 2,
                                 TZTOPORT_OBSERVACIONES = 'Se actualiza la fecha de cierre '
                            Where TZTCONTACT_ID = cx.TZTCONTACT_ID
                            And TZTOPORT_ID = cx.TZTOPORT_ID
                            And TZTOPORT_OPORTUNIDAD = cx.TZTOPORT_OPORTUNIDAD;
                       Exception
                        When Others then 
                         null;
                       End;
                    
                    End if; 
                
                
                End loop cx1;
        
        End loop cx;  
        Commit;

  End Actualiza_hijo;    
  

END PKG_INCONC_UPSELLING;
/

DROP PUBLIC SYNONYM PKG_INCONC_UPSELLING;

CREATE OR REPLACE PUBLIC SYNONYM PKG_INCONC_UPSELLING FOR BANINST1.PKG_INCONC_UPSELLING;
