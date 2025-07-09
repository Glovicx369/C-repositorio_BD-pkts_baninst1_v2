DROP PACKAGE BODY BANINST1.PKG_REPORTES_1;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_REPORTES_1 IS

PROCEDURE sp_pagos_con_referencia
IS

       vl_cadena varchar2(500);

        BEGIN

                    delete tszpaco;
                    Commit;

                  for c in (
                    select distinct TBRACCD_PIDM pidm,
                    spriden_id Matricula,
                    SPRIDEN_LAST_NAME ||' '||SPRIDEN_FIRST_NAME Nombre,
                    GORADID_ADDITIONAL_ID Referencia,
                    GOREMAL_EMAIL_ADDRESS Correo,
                    TBRACCD_TRAN_NUMBER secuencia_Banner,
                    TBRACCD_PAYMENT_ID id_pago,
                    TBRACCD_AMOUNT Monto,
                    TRUNC (TBRACCD_TRANS_DATE) Fecha_Pago,
                    TRUNC (TBRACCD_ENTRY_DATE) Fecha_Registro,
                    TBRACCD_DETAIL_CODE codigo,
                    tbbdetc_desc descrip
                    from  tbbdetc, spriden, goradid, GOREMAL a, tbraccd
                    Where  TBRACCD_DETAIL_CODE = tbbdetc_detail_code
                    And TBRACCD_DETAIL_CODE in (select a1.tbbdetc_detail_code
                                                                     from tbbdetc a1
                                                                     Where  TBBDETC_DCAT_CODE = 'CSH')
                    And TBRACCD_AMOUNT >0
                    And spriden_pidm = TBRACCD_PIDM
                    and SPRIDEN_CHANGE_IND is null
                    And goradid_pidm = spriden_pidm (+)
                    and GORADID_ADID_CODE like 'REF%'
                    And a.GOREMAL_PIDM = spriden_pidm (+)
                    And a.GOREMAL_SURROGATE_ID = (select max (GOREMAL_SURROGATE_ID)
                                                                        from GOREMAL a1
                                                                        Where a1.GOREMAL_PIDM = a.GOREMAL_PIDM
                                                                        And a1.GOREMAL_EMAIL_ADDRESS like '%@%')
                    ORDER BY 9 DESC
                       ) loop

                                            vl_cadena := null;
                                             for cadena in (Select TBRACDT_TEXT, TBRACDT_SEQ_NUMBER
                                                                    from TBRACDT
                                                                    where TBRACDT_PIDM = c.pidm
                                                                    and TBRACDT_TRAN_NUMBER = c.secuencia_Banner
                                                                    order by 2 ) loop

                                                                  vl_cadena :=  vl_cadena || cadena.TBRACDT_TEXT;
                                                                          --dbms_output.put_line('cadena' ||vl_cadena );
                                             End loop;

                 Insert into tszpaco values (c.pidm,
                                                       c.matricula,
                                                       c.nombre,
                                                       c.referencia,
                                                       c.correo,
                                                       c.secuencia_banner,
                                                       c.id_pago,
                                                       c.monto,
                                                       c.fecha_pago,
                                                       c.fecha_registro,
                                                       c.codigo,
                                                       c.descrip,
                                                       vl_cadena);

                 end loop;
                 commit;
          END;


PROCEDURE sp_moras
IS

    BEGIN

                  Begin

                        delete TZTMORA;
                        Commit;

                        For mora in (

                        select distinct c.TBRACCD_PIDM pidm,
                        b.spriden_id Matricula,
                        b.SPRIDEN_LAST_NAME ||' '||b.SPRIDEN_FIRST_NAME Nombre,
                        c.TBRACCD_Balance Saldo,
                        TRUNC (c.TBRACCD_EFFECTIVE_DATE) Fecha_cargo,
                         ceil ((sysdate) - TRUNC (c.TBRACCD_EFFECTIVE_DATE))   dias ,
                        c.TBRACCD_DETAIL_CODE codigo,
                        a.tbbdetc_desc descrip,
                        a.TBBDETC_DCAT_CODE
                        from  tbbdetc a, spriden b, tbraccd c
                        Where  c.TBRACCD_DETAIL_CODE = a.tbbdetc_detail_code
                        And c.TBRACCD_DETAIL_CODE in (select a1.tbbdetc_detail_code
                                                                         from tbbdetc a1
                                                                         Where  a.TBBDETC_TYPE_IND = a1.TBBDETC_TYPE_IND)
                        and a.TBBDETC_TYPE_IND = 'C'
                        And c.TBRACCD_AMOUNT >0
                        And c.tbraccd_balance > 0
                        And b.spriden_pidm = TBRACCD_PIDM
                        and b.SPRIDEN_CHANGE_IND is null
                        ORDER BY 1, 9 DESC


                        ) loop

                        Insert into TZTMORA values (mora.pidm,
                                                                    mora.matricula,
                                                                    mora.nombre,
                                                                    mora.saldo,
                                                                    mora.fecha_cargo,
                                                                    mora.dias,
                                                                    mora.descrip,
                                                                    null);

                         End Loop;

                        End;


                        Begin

                        for estat in (select distinct b.sgbstdn_pidm pidm, b.SGBSTDN_STST_CODE estatus
                        from TZTMORA a, sgbstdn b
                        Where a.TZTMORA_PIDM = b.sgbstdn_pidm
                        And b.SGBSTDN_TERM_CODE_EFF = (select max ( b1.SGBSTDN_TERM_CODE_EFF)
                                                                                from SGBSTDN b1
                                                                                where b.sgbstdn_pidm = b1.sgbstdn_pidm) ) loop

                         Update  TZTMORA
                         set   TZTMORA_ESTATUS = estat.estatus
                         where TZTMORA_PIDM= estat.pidm;
                         End Loop;
                         Commit;

                        End;


                        Begin
                        For act in ( select distinct TZTMORA_pidm pidm, TZTMORA_DIAS dias
                        from TZTMORA a
                        where a.TZTMORA_DIAS = (select max (a1.TZTMORA_DIAS)
                                                             from TZTMORA a1
                                                             where a.TZTMORA_pidm = a1.TZTMORA_pidm)
                        order by 1) loop

                        Update TZTMORA
                        set  TZTMORA_DIAS = act.dias
                        where TZTMORA_pidm = act.pidm;
                        End Loop;
                        Commit;
                        End;

                END;


PROCEDURE sp_moras_col
IS

    BEGIN

                  Begin

                        delete TZTMORA_col;
                        Commit;

                        For mora in (

                        select distinct c.TBRACCD_PIDM pidm,
                        b.spriden_id Matricula,
                        b.SPRIDEN_LAST_NAME ||' '||b.SPRIDEN_FIRST_NAME Nombre,
                        c.TBRACCD_Balance Saldo,
                        TRUNC (c.TBRACCD_EFFECTIVE_DATE) Fecha_cargo,
                         ceil ((sysdate) - TRUNC (c.TBRACCD_EFFECTIVE_DATE))   dias ,
                        c.TBRACCD_DETAIL_CODE codigo,
                        a.tbbdetc_desc descrip,
                        a.TBBDETC_DCAT_CODE
                        from  tbbdetc a, spriden b, tbraccd c
                        Where  c.TBRACCD_DETAIL_CODE = a.tbbdetc_detail_code
                        And c.TBRACCD_DETAIL_CODE in (select a1.tbbdetc_detail_code
                                                                         from tbbdetc a1
                                                                         Where  a.TBBDETC_TYPE_IND = a1.TBBDETC_TYPE_IND)
                        and a.TBBDETC_TYPE_IND = 'C'
                        and a.TBBDETC_DCAT_CODE = 'COL'
                        And c.TBRACCD_AMOUNT >0
                        And c.tbraccd_balance > 0
                        And b.spriden_pidm = TBRACCD_PIDM
                        and b.SPRIDEN_CHANGE_IND is null
                        ORDER BY 1, 9 DESC


                        ) loop

                        Insert into TZTMORA_col values (mora.pidm,
                                                                    mora.matricula,
                                                                    mora.nombre,
                                                                    mora.saldo,
                                                                    mora.fecha_cargo,
                                                                    mora.dias,
                                                                    mora.descrip,
                                                                    null);

                         End Loop;

                        End;


                        Begin

                        for estat in (select distinct b.sgbstdn_pidm pidm, b.SGBSTDN_STST_CODE estatus
                        from TZTMORA_col a, sgbstdn b
                        Where a.TZTMORA_PIDM = b.sgbstdn_pidm
                        And b.SGBSTDN_TERM_CODE_EFF = (select max ( b1.SGBSTDN_TERM_CODE_EFF)
                                                                                from SGBSTDN b1
                                                                                where b.sgbstdn_pidm = b1.sgbstdn_pidm) ) loop

                         Update  TZTMORA_col
                         set   TZTMORA_ESTATUS = estat.estatus
                         where TZTMORA_PIDM= estat.pidm;
                         End Loop;
                         Commit;

                        End;


                        Begin
                        For act in ( select distinct TZTMORA_pidm pidm, TZTMORA_DIAS dias
                        from TZTMORA_col a
                        where a.TZTMORA_DIAS = (select max (a1.TZTMORA_DIAS)
                                                             from TZTMORA_col a1
                                                             where a.TZTMORA_pidm = a1.TZTMORA_pidm)
                        order by 1) loop

                        Update TZTMORA_col
                        set  TZTMORA_DIAS = act.dias
                        where TZTMORA_pidm = act.pidm;
                        End Loop;
                        Commit;
                        End;

                END;

Function  f_saldototal (p_pidm in number) return varchar2

Is

vl_monto number:=0;
vl_moneda varchar2(10);

    Begin
            select sum(nvl (tbraccd_balance, 0)) balance
            Into vl_monto
            from tbraccd
            Where tbraccd_pidm =  p_pidm; --39423
           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
        Return (vl_monto);
        --Return(vl_moneda);
       END f_saldototal;


Function  f_saldodia (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
    Begin

  select sum(nvl (tbraccd_balance, 0)) balance
            Into vl_monto
            from tbraccd, TBBDETC
            Where tbraccd_pidm = p_pidm
           And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
--            And TBBDETC_TYPE_IND = 'C'
            And TBRACCD_EFFECTIVE_DATE <= trunc(sysdate); --39423

           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
        vl_moneda:=Null;
      Return (vl_monto);
    --  Return(vl_moneda);
    END f_saldodia;



Function  f_cargo_vencidos (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
    Begin



  select count (*) cargos
            Into vl_monto
            from tbraccd, TBBDETC
            Where tbraccd_pidm = p_pidm
           And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
            And TBBDETC_TYPE_IND = 'C'
            And TBRACCD_EFFECTIVE_DATE <= trunc(sysdate) --39423
            And tbraccd_balance > 0;

           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
        vl_moneda:=Null;
      Return (vl_monto);
    --  Return(vl_moneda);
    END f_cargo_vencidos;


Function  f_fecha_pago_vieja (p_pidm in number ) return varchar2

is

vl_fecha varchar2(10);

Begin
 select distinct min (TBRACCD_EFFECTIVE_DATE)
            Into vl_fecha
            from tbraccd, TBBDETC
            Where tbraccd_pidm = p_pidm
           And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
            And TBBDETC_TYPE_IND = 'C'
            And TBRACCD_EFFECTIVE_DATE <= trunc(sysdate) --39423
            And tbraccd_balance > 0;

           Return (vl_fecha);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_fecha:=Null;
      Return (vl_fecha);
    --  Return(vl_moneda);
    END f_fecha_pago_vieja;

Function  f_fecha_pago_alta (p_pidm in number ) return varchar2

is

vl_fecha varchar2(10);

Begin
 select distinct max (TBRACCD_EFFECTIVE_DATE)
            Into vl_fecha
            from tbraccd, TBBDETC
            Where tbraccd_pidm = p_pidm
           And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
            And TBBDETC_TYPE_IND = 'C'
            And TBRACCD_EFFECTIVE_DATE <= trunc(sysdate) --39423
            And tbraccd_balance > 0;

           Return (vl_fecha);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_fecha:=Null;
      Return (vl_fecha);
    --  Return(vl_moneda);
    END f_fecha_pago_alta;

Function  f_dias_atraso (p_pidm in number ) return varchar2

is

vl_dias varchar2(10);

Begin

    select distinct TZTMORA_DIAS
        Into vl_dias
    from tbraccd, TZTMORA
    Where tbraccd_pidm = TZTMORA_pidm
    and TZTMORA_DIAS >= 1
    And tbraccd_pidm = p_pidm;

           Return (vl_dias);
    Exception
    when Others then
        vl_dias:=Null;
      Return (vl_dias);
    --  Return(vl_moneda);
    END f_dias_atraso;


 Function f_mora  (p_pidm in number ) return varchar2

is

vl_Mora varchar2(10);

Begin



select     distinct case
            when TZTMORA_dias between 1 and 30 then
                     'Mora1'
            when TZTMORA_dias between 31 and 60 then
                     'Mora2'
            when TZTMORA_dias between 61 and 90 then
                    'Mora3'
            when TZTMORA_dias between 91 and 120 then
                    'Mora4'
            when TZTMORA_dias between 121 and 150 then
                    'Mora5'
when TZTMORA_dias between 151 and 180 then
                    'Mora6'
            when TZTMORA_dias > 180 then
                    'Mora7'
            End as Mora
            Into vl_Mora
from TZTMORA
Where TZTMORA_PIDM = p_pidm;

         Return (vl_Mora);
    Exception
    when Others then
        vl_Mora:=Null;
      Return (vl_Mora);
    --  Return(vl_moneda);
    END f_mora;

Function  f_cargo_total_futuro (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
    Begin



  select sum (tbraccd_balance)
            Into vl_monto
            from tbraccd, TBBDETC
            Where tbraccd_pidm = p_pidm
           And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
            And TBBDETC_TYPE_IND = 'C'
            And TBRACCD_EFFECTIVE_DATE > trunc(sysdate) --39423
            And tbraccd_balance > 0;

           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
      Return (vl_monto);
    --  Return(vl_moneda);
    END f_cargo_total_futuro;


Function  f_saldocorte (p_pidm in number ) RETURN  varchar2

As


vl_vencimiento number;
vl_fecha varchar2(10);
vl_monto number:=0;
vl_moneda varchar2(10);
vl_mes varchar2(2);
 v_error varchar2(4000);
 vl_vence varchar2(10);
 vl_secuencia number:=0;


        Begin

            Begin
                select distinct to_number (decode (substr (sgbstdn_rate_code, 4, 1), 'A', 15, 'B', '30', 'C', '10')) vencimiento
                    Into vl_vencimiento
                from sgbstdn
                Where sgbstdn_pidm = p_pidm;
            Exception
                When Others then
                vl_vencimiento := 10;
            End;


           Begin
              select to_char (sysdate,'YYYY/MM')
                Into vl_fecha
              from dual;
           End;



           Begin
              select to_char (sysdate,'MM')
                Into vl_mes
              from dual;
           End;

           If  vl_mes = '02' and vl_vencimiento = '30' then
               vl_vencimiento := '28';
           End if;

          vl_vence :=   (vl_fecha||'/'|| vl_vencimiento);



               BEGIN

                            select min (TBRACCD_TRAN_NUMBER),  nvl (a.tbraccd_balance, 0)
                              into vl_secuencia, vl_monto
                            from tbraccd a
                            where a.tbraccd_pidm = p_pidm
                            And a.tbraccd_balance > 0
                            And trunc (a.TBRACCD_EFFECTIVE_DATE) >  to_date (vl_vence,'rrrr/mm/dd')
                            group by a.tbraccd_balance;

              Exception
              When Others then
                vl_monto :=0;
                vl_secuencia :=0;

              End;
           RETURN (vl_monto);
        Exception
        when Others then
        vl_monto :=0;

        RETURN (vl_monto);
        End f_saldocorte;


Function  f_cargo_Numero_futuro (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
    Begin



  select count (*)
            Into vl_monto
            from tbraccd, TBBDETC
            Where tbraccd_pidm = p_pidm
           And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
            And TBBDETC_TYPE_IND = 'C'
            And TBRACCD_EFFECTIVE_DATE > trunc(sysdate) --39423
            And tbraccd_balance > 0;

           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
      Return (vl_monto);
    --  Return(vl_moneda);
    END f_cargo_Numero_futuro;


Function  f_fechacorte (p_pidm in number ) RETURN  varchar2

As


vl_vencimiento number;
vl_fecha varchar2(10);
vl_monto varchar2(10);
vl_moneda varchar2(10);
vl_mes varchar2(2);
 v_error varchar2(4000);
 vl_vence varchar2(10);
 vl_secuencia number:=0;


        Begin

            Begin
                select distinct to_number (decode (substr (sgbstdn_rate_code, 4, 1), 'A', 15, 'B', '30', 'C', '10')) vencimiento
                    Into vl_vencimiento
                from sgbstdn
                Where sgbstdn_pidm = p_pidm;
            Exception
                When Others then
                vl_vencimiento := 10;
            End;


  dbms_output.put_line('rate:'||vl_vencimiento);

           Begin
              select to_char (sysdate,'YYYY/MM')
                Into vl_fecha
              from dual;
           End;


  dbms_output.put_line('vl_fecha:'||vl_fecha);

           Begin
              select to_char (sysdate,'MM')
                Into vl_mes
              from dual;
           End;

             dbms_output.put_line('vl_mes:'||vl_mes);

           If  vl_mes = '02' and vl_vencimiento = '30' then
               vl_vencimiento := '28';
           End if;

          vl_vence :=   (vl_fecha||'/'|| vl_vencimiento);


             dbms_output.put_line('vl_vence:'||vl_vence);


               BEGIN

                            select min (TBRACCD_TRAN_NUMBER), trunc (TBRACCD_EFFECTIVE_DATE)
                              into vl_secuencia, vl_monto
                            from tbraccd a
                            where a.tbraccd_pidm = p_pidm
                            And a.tbraccd_balance > 0
                            And trunc (a.TBRACCD_EFFECTIVE_DATE) =  to_date (vl_vence,'rrrr/mm/dd')
                            group by a.TBRACCD_EFFECTIVE_DATE;





              Exception
              When Others then
                vl_monto :=null;
                vl_secuencia :=0;

              End;

                           dbms_output.put_line('vl_monto:'||vl_monto);
                           dbms_output.put_line('vl_secuencia:'||vl_secuencia);

           RETURN (vl_monto);
        Exception
        when Others then
        vl_monto :=null;

        RETURN (vl_monto);
        End f_fechacorte;


Function  f_pago_total (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
    Begin



  select sum (TBRACCD_AMOUNT)
            Into vl_monto
            from tbraccd, TBBDETC
            Where tbraccd_pidm = p_pidm
           And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
            And TBBDETC_TYPE_IND = 'P'
            and TBBDETC_DCAT_CODE = 'CSH'
            and TBRACCD_TRAN_NUMBER NOT IN
              -- Para los cargos negativos que se matan asi  mismos
                                     (SELECT TBRACCD_TRAN_NUMBER
                                        FROM TBRACCD, TBBDETC
                                        WHERE     TBRACCD_PIDM = p_pidm
                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        AND TBBDETC_TYPE_IND = 'C'
                                        AND TBRACCD_AMOUNT < 0
                                        UNION
                                        SELECT TBRAPPL_CHG_TRAN_NUMBER
                                        FROM TBRAPPL,TBRACCD
                                        WHERE TBRACCD_PIDM = p_pidm
                                        AND TBRAPPL_PIDM= TBRACCD_PIDM
                                        AND TBRAPPL_REAPPL_IND IS NULL
                                        AND TBRAPPL_PAY_TRAN_NUMBER IN (
                                                                                                SELECT TBRACCD_TRAN_NUMBER
                                                                                                FROM TBRACCD, TBBDETC
                                                                                                WHERE     TBRACCD_PIDM = p_pidm
                                                                                                AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                                                                                AND TBBDETC_TYPE_IND = 'C'
                                                                                                AND TBRACCD_AMOUNT < 0
                                                                                                )
--                                        UNION
--                                        SELECT TBRACCD_TRAN_NUMBER_PAID
--                                        FROM TBRACCD, TBBDETC
--                                        WHERE     TBRACCD_PIDM = :p_pidm
--                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
--                                        AND TBBDETC_TYPE_IND = 'C'
--                                        AND TBRACCD_AMOUNT < 0
                                         );
           -- And TBRACCD_EFFECTIVE_DATE > trunc(sysdate) --39423
           -- And tbraccd_balance > 0;

           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
      Return (vl_monto);
    --  Return(vl_moneda);
    END f_pago_total;


Function  f_num_total_pago (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
    Begin



          select count(*)
            Into vl_monto
            from tbraccd, TBBDETC
            Where tbraccd_pidm = p_pidm
           And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
            And TBBDETC_TYPE_IND = 'P'
            and TBBDETC_DCAT_CODE = 'CSH'
            and TBRACCD_TRAN_NUMBER NOT IN
              -- Para los cargos negativos que se matan asi  mismos
                                     (SELECT TBRACCD_TRAN_NUMBER
                                        FROM TBRACCD, TBBDETC
                                        WHERE     TBRACCD_PIDM = p_pidm
                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        AND TBBDETC_TYPE_IND = 'C'
                                        AND TBRACCD_AMOUNT < 0
                                        UNION
                                        SELECT TBRAPPL_CHG_TRAN_NUMBER
                                        FROM TBRAPPL,TBRACCD
                                        WHERE TBRACCD_PIDM = p_pidm
                                        AND TBRAPPL_PIDM= TBRACCD_PIDM
                                        AND TBRAPPL_REAPPL_IND IS NULL
                                        AND TBRAPPL_PAY_TRAN_NUMBER IN (
                                                                                                SELECT TBRACCD_TRAN_NUMBER
                                                                                                FROM TBRACCD, TBBDETC
                                                                                                WHERE     TBRACCD_PIDM = p_pidm
                                                                                                AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                                                                                AND TBBDETC_TYPE_IND = 'C'
                                                                                                AND TBRACCD_AMOUNT < 0
                                                                                                )
--                                        UNION
--                                        SELECT TBRACCD_TRAN_NUMBER_PAID
--                                        FROM TBRACCD, TBBDETC
--                                        WHERE     TBRACCD_PIDM = :p_pidm
--                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
--                                        AND TBBDETC_TYPE_IND = 'C'
--                                        AND TBRACCD_AMOUNT < 0
                                         );
           -- And TBRACCD_EFFECTIVE_DATE > trunc(sysdate) --39423
           -- And tbraccd_balance > 0;

           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
      Return (vl_monto);
    --  Return(vl_moneda);
    END f_num_total_pago;


 Function  f_jornada (p_pidm in number ) RETURN  varchar2
 Is

vl_Jornada varchar2 (10);


    Begin

                select x.SGRSATT_ATTS_CODE
                 Into vl_Jornada
                from (
                        select DISTINCT b.SGRSATT_ATTS_CODE
                        from SORLCUR a
                        left outer join SGRSATT b on a.SORLCUR_PIDM = b.SGRSATT_PIDM
                            and b.SGRSATT_STSP_KEY_SEQUENCE = a.SORLCUR_KEY_SEQNO
                            and b.SGRSATT_TERM_CODE_EFF = a.SORLCUR_TERM_CODE
                            And regexp_like (b.SGRSATT_ATTS_CODE, '^[0-9]')
                            And b.SGRSATT_SURROGATE_ID = (Select max (b1.SGRSATT_SURROGATE_ID)
                                                                                        from SGRSATT b1
                                                                                        where b.SGRSATT_PIDM = b1.SGRSATT_PIDM
                                                                                        )
                        where a.SORLCUR_LMOD_CODE = 'LEARNER'
                            And a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
                                                                        from SORLCUR a1
                                                                        where a.SORLCUR_pidm = a1.SORLCUR_pidm
                                                                        And a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
                            and a.sorlcur_pidm = p_pidm
                        union
                        select DISTINCT b.SGRSATT_ATTS_CODE
                        from SORLCUR a
                        left outer join SGRSATT b on a.SORLCUR_PIDM = b.SGRSATT_PIDM
                            And regexp_like (b.SGRSATT_ATTS_CODE, '^[0-9]')
                            And b.SGRSATT_SURROGATE_ID = (Select max (b1.SGRSATT_SURROGATE_ID)
                                                                                        from SGRSATT b1
                                                                                        where b.SGRSATT_PIDM = b1.SGRSATT_PIDM
                                                                                        )
                        where a.SORLCUR_LMOD_CODE = 'LEARNER'
                            And a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
                                                                        from SORLCUR a1
                                                                        where a.SORLCUR_pidm = a1.SORLCUR_pidm
                                                                            And a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
                            and a.sorlcur_pidm = p_pidm
                ) x
                where x.SGRSATT_ATTS_CODE is not null;


           Return (vl_Jornada);
    Exception
    when Others then
        vl_Jornada :=null;
      Return (vl_Jornada);
    END f_jornada;




Function  f_no_materia (p_pidm in number ) RETURN  varchar2

Is

vl_Jornada number:=0;

    Begin
                SELECT DISTINCT  count (1)
                        Into vl_Jornada
                     FROM ssbsect a , SFRSTCR b
                    WHERE     a.SSBSECT_TERM_CODE = b.SFRSTCR_TERM_CODE
                          AND b.SFRSTCR_CRN = a.SSBSECT_CRN
                          AND b.SFRSTCR_GRDE_CODE IS NULL
                          AND b.SFRSTCR_RSTS_CODE = 'RE'
                          And b.SFRSTCR_TERM_CODE = (select max (b1.SFRSTCR_TERM_CODE)
                                                                            from SFRSTCR b1
                                                                            Where b.SFRSTCR_pidm = b1.SFRSTCR_pidm)
                          AND b.SFRSTCR_PIDM = p_pidm;


           Return (vl_Jornada);
    Exception
    when Others then
        vl_Jornada :=null;
      Return (vl_Jornada);
    END f_no_materia;

 Function  f_fecha_Matriculacion (p_pidm in number ) RETURN  varchar2

 Is

 vl_fecha_matricula varchar2(10);

 Begin

         Select b.STVTERM_START_DATE
            Into vl_fecha_matricula
          from sorlcur a, stvterm b
          where a.SORLCUR_LMOD_CODE = 'ADMISSIONS'
          And a.SORLCUR_SEQNO in (select min (a1.SORLCUR_SEQNO)
                                                    from SORLCUR a1
                                                    Where a.sorlcur_pidm = a1.sorlcur_pidm
                                                    and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
          And a.SORLCUR_TERM_CODE_MATRIC = b.STVTERM_CODE
         And a.sorlcur_pidm = p_pidm;

        Return (vl_fecha_matricula);
    Exception
    when Others then
        vl_fecha_matricula :=null;
      Return (vl_fecha_matricula);
    END f_fecha_Matriculacion;

  Function  f_periodo_inicial (p_pidm in number ) RETURN  varchar2
  Is

  vl_periodo_inicial varchar2(10);

     Begin
                SELECT DISTINCT  SFRSTCR_TERM_CODE
                      Into vl_periodo_inicial
                     FROM ssbsect a , SFRSTCR b
                    WHERE     a.SSBSECT_TERM_CODE = b.SFRSTCR_TERM_CODE
                          AND b.SFRSTCR_CRN = a.SSBSECT_CRN
                          And b.SFRSTCR_TERM_CODE = (select min (b1.SFRSTCR_TERM_CODE)
                                                                            from SFRSTCR b1
                                                                            Where b.SFRSTCR_pidm = b1.SFRSTCR_pidm)
                          AND b.SFRSTCR_PIDM = p_pidm;


           Return (vl_periodo_inicial);
    Exception
    when Others then
        vl_periodo_inicial :=null;
      Return (vl_periodo_inicial);
    END f_periodo_inicial;

Function  f_Estado_programa (p_pidm in number ) RETURN  varchar2

Is

    vl_estatus varchar2(50);

    Begin

            select  distinct  STVSTST_DESC
               Into vl_estatus
            from sorlcur c , sgbstdn a, spriden b, stvSTST d
            where c.SORLCUR_LMOD_CODE = 'LEARNER'
            And c.SORLCUR_SEQNO in (select max ( c1.SORLCUR_SEQNO)
                                                      from SORLCUR c1
                                                      where c.sorlcur_pidm = c1.sorlcur_pidm
                                                      and c.SORLCUR_LMOD_CODE =  c1.SORLCUR_LMOD_CODE
                                                      )
            and c.sorlcur_pidm = a.sgbstdn_pidm
            and c.sorlcur_program = a.sgbstdn_program_1
            and a.SGBSTDN_TERM_CODE_EFF in (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                        from SGBSTDN a1
                                                                        Where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                        And a.sgbstdn_program_1 = a1.sgbstdn_program_1)
            and b.spriden_pidm = a.sgbstdn_pidm
            and a.SGBSTDN_STST_CODE = stvSTST_code
            and b.spriden_change_ind is null
            and b.spriden_pidm = p_pidm;


           Return (vl_estatus);
    Exception
    when Others then
        vl_estatus :=null;
      Return (vl_estatus);
    END f_Estado_programa;

    Function  f_Descuento (p_pidm in number ) RETURN  varchar2
    Is

    vl_descuento varchar2(10);
    Begin

            Select b.TBREDET_PERCENT
                Into vl_descuento
            from TBBESTU a, TBREDET b
            where a.TBBESTU_EXEMPTION_CODE = b.TBREDET_EXEMPTION_CODE
            and a.TBBESTU_TERM_CODE = b.TBREDET_TERM_CODE
            and a.TBBESTU_TERM_CODE in (select max (a1.TBBESTU_TERM_CODE)
                                                            from TBBESTU a1
                                                            Where a.TBBESTU_PIDM = a1.TBBESTU_PIDM)
           and a.TBBESTU_PIDM   = p_pidm;

         Return (vl_descuento);
    Exception
    when Others then
    vl_descuento :=null;
    Return (vl_descuento);


    End f_Descuento;

Procedure sp_Consulta_Cartera

is


    Begin

        Begin

--                delete TZTCRTE
--                where TZTCRTE_TIPO_REPORTE = 'Cartera_Relacion_cargo_cargo';
--                Commit;
--
                FOR cartera in (

            WITH alumno as (
                Select distinct   b.spriden_pidm pidm,
                                b.spriden_id Matricula,
                                b.spriden_first_name||' '||spriden_last_name Estudiante,
                                d.SGBSTDN_STST_CODE Estatus_Code ,
                                STVSTST_DESC Estatus,
                                SZVCAMP_CAMP_CODE Campus,
                                a.SORLCUR_LEVL_CODE Nivel,
                                a.SORLCUR_PROGRAM  Programa,
                                 c.SMRPRLE_PROGRAM_DESC Desc_Programa ,
                                STVSTYP_DESC TIPO,
                                vend.saracmt_comment_text clave_canal,
                                geo.STVGEOD_DESC canal_final
        from sorlcur a
        join spriden b on b.spriden_pidm = a.sorlcur_pidm and b.spriden_change_ind is null
        join  sgbstdn d on  d.sgbstdn_pidm=spriden_pidm
        And d.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
                                                               from SGBSTDN b1
                                                               Where d.sgbstdn_pidm = b1.sgbstdn_pidm)
        join SMRPRLE c  on c.SMRPRLE_PROGRAM = A.SORLCUR_PROGRAM
        join STVSTST on d.sgbstdn_stst_code=STVSTST_CODE
        join SZVCAMP on szvcamp_camp_alt_code=substr(a.sorlcur_term_code,1,2)
        join SARADAP s on saradap_pidm=sorlcur_pidm and saradap_program_1=sorlcur_program
              and SARADAP_TERM_CODE_ENTRY in (select max(saradap_term_code_entry) from saradap ss
                                                                       where s.saradap_pidm=ss.saradap_pidm and s.saradap_program_1=ss.saradap_program_1)
        left outer join SARACMT vend ON vend.saracmt_pidm = s.saradap_pidm
                                                     and vend.saracmt_term_code = s.saradap_term_code_entry
                                                     and vend.saracmt_appl_no = s.saradap_appl_no
                                                     and vend.saracmt_orig_code='CANF'
                                                     and vend.SARACMT_SEQNO in  (select max (cmt.SARACMT_SEQNO)
                                                                                                    from SARACMT cmt
                                                                                                     Where cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                                                    And cmt.SARACMT_TERM_CODE = vend.SARACMT_TERM_CODE
                                                                                                    And cmt.SARACMT_APPL_NO = vend.SARACMT_APPL_NO
                                                                                                    And cmt.saracmt_orig_code='CANF')
        left outer join STVGEOD geo on lpad (trim (substr (vend.SARACMT_COMMENT_TEXT, 1, 2)), 2, '0') = geo.STVGEOD_CODE
        join STVSTYP on d.SGBSTDN_STYP_CODE=STVSTYP_CODE
        left outer join SARAPPD ss on sarappd_pidm=saradap_pidm and sarappd_term_code_entry=saradap_term_code_entry
                                                                                                and sarappd_appl_no=saradap_appl_no
                                                                                                and SARAPPD_SEQ_NO =(select max(SARAPPD_SEQ_NO)
                                                                                                                                      from SARAPPD s
                                                                                                                                      where ss.sarappd_pidm = s.sarappd_pidm
                                                                                                                                      and ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY)
        Where a.SORLCUR_LMOD_CODE = 'LEARNER'
        And a.sorlcur_pidm in (select sorlcur_pidm
                                          from sorlcur aa
                                          where a.sorlcur_program=aa.sorlcur_program
                                          and a.sorlcur_lmod_code=aa.sorlcur_lmod_code
                                          and a.sorlcur_roll_ind=aa.sorlcur_roll_ind)
        and a.SORLCUR_SEQNO = (select max (SORLCUR_SEQNO)
                                                from SORLCUR aa1
                                                Where a.sorlcur_pidm = aa1.sorlcur_pidm
                                                And a.SORLCUR_LMOD_CODE = aa1.SORLCUR_LMOD_CODE
                                                And a.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE
                                                And a.SORLCUR_KEY_SEQNO = aa1.SORLCUR_KEY_SEQNO
                                                And a.sorlcur_program=aa1.sorlcur_program)
        union
         Select distinct  b.spriden_pidm pidm,
                              b.spriden_id Matricula,
                              b.spriden_first_name||' '||b.spriden_last_name Estudiante,
                              null Estatus_Code ,
                              null Estatus,
                              SZVCAMP_CAMP_CODE Campus,
                              a.SORLCUR_LEVL_CODE Nivel,
                              a.SORLCUR_PROGRAM Programa,
                              c.SMRPRLE_PROGRAM_DESC Desc_Programa,
                              'NUEVO INGRESO' TIPO,
                             saracmt_comment_text clave_canal,
                             STVGEOD_DESC canal_final
        from sorlcur a
        join spriden b on b.spriden_pidm = a.sorlcur_pidm
                            and b.spriden_change_ind is null
        join SMRPRLE c  on c.SMRPRLE_PROGRAM = A.SORLCUR_PROGRAM
        join SZVCAMP on szvcamp_camp_alt_code=substr(a.sorlcur_term_code,1,2)
        join SARADAP s on saradap_pidm=sorlcur_pidm
                                and saradap_term_code_entry=sorlcur_term_code
                                and saradap_program_1=sorlcur_program
                                and SARADAP_TERM_CODE_ENTRY in (select max(saradap_term_code_entry)
                                                                                        from saradap ss
                                                                                       where s.saradap_pidm=ss.saradap_pidm
                                                                                       and s.saradap_program_1=ss.saradap_program_1)
        left outer join SARACMT vend  ON vend.saracmt_pidm = s.saradap_pidm
                                                     and vend.saracmt_term_code = s.saradap_term_code_entry
                                                     and vend.saracmt_appl_no = s.saradap_appl_no
                                                     and vend.saracmt_orig_code='CANF'
                                                     and vend.SARACMT_SEQNO in  (select max (cmt.SARACMT_SEQNO)
                                                                                                    from SARACMT cmt
                                                                                                     Where cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                                                    And cmt.SARACMT_TERM_CODE = vend.SARACMT_TERM_CODE
                                                                                                    And cmt.SARACMT_APPL_NO = vend.SARACMT_APPL_NO
                                                                                                    And cmt.saracmt_orig_code='CANF')
        left outer join STVGEOD geo on lpad (trim (substr (vend.SARACMT_COMMENT_TEXT, 1, 2)), 2, '0') = geo.STVGEOD_CODE
        left outer join SARAPPD ss on sarappd_pidm=saradap_pidm
                                                and sarappd_term_code_entry=saradap_term_code_entry
                                                and sarappd_appl_no=saradap_appl_no
                                                and SARAPPD_SEQ_NO =(select max(SARAPPD_SEQ_NO)
                                                                                      from SARAPPD s
                                                                                      where ss.sarappd_pidm = s.sarappd_pidm
                                                                                      and ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY)
        Where a.sorlcur_pidm not in (select sgbstdn_pidm from sgbstdn where sgbstdn_levl_code=a.sorlcur_levl_code)
        union
         Select distinct  b.spriden_pidm pidm,
                              b.spriden_id Matricula,
                              b.spriden_first_name||' '||b.spriden_last_name Estudiante,
                              null Estatus_Code ,
                              null Estatus,
                              SZVCAMP_CAMP_CODE Campus,
                              null Nivel,
                              null Programa,
                              null Desc_Programa,
                              'PERSONA_GENERAL' TIPO,
                             GORADID_ADDITIONAL_ID clave_canal,
                             STVGEOD_DESC canal_final
        from  spriden b
        join SZVCAMP on szvcamp_camp_alt_code=substr(b.spriden_id,1,2)
        left outer join GORADID gora on gora.GORADID_PIDM = b.spriden_pidm
                             and GORADID_ADID_CODE = 'CANI'
        left outer join STVGEOD geo on lpad (trim (substr (gora.GORADID_ADDITIONAL_ID, 1, 2)), 2, '0') = geo.STVGEOD_CODE
        Where b.spriden_pidm not in (select sgbstdn_pidm from sgbstdn )
        And b.spriden_pidm not in (select saradap_pidm from saradap )
        and b.spriden_change_ind is null
        and b.spriden_id not in  ('0198%')
        ) ,
        pagos_ppl as (
           select TBRAPPL_PIDM pidm, TBRAPPL_PAY_TRAN_NUMBER Pago, TBRAPPL_CHG_TRAN_NUMBER Cargo, TBRAPPL_AMOUNT Monto, TBRAPPL_ACTIVITY_DATE fecha
           from tbrappl
           where TBRAPPL_REAPPL_IND is null
            )  ,
         pagos_ccd as (
           select tbraccd_pidm pidm, tbraccd_tran_number seq_pago, tbraccd_detail_code codigo,  tbbdetc_desc descrip , TBRACCD_TRANS_DATE fecha_pago,
                    TBRACCD_ENTRY_DATE fecha_captura, TBRACCD_USER usuario_id
           from tbraccd a, tbbdetc b
           where a.tbraccd_detail_code = b.tbbdetc_detail_code
           -- and b.TBBDETC_TYPE_IND = 'C'
          ),
          IVA as (
          select
            TVRTAXD_PIDM,
            TVRTAXD_ACCD_TRAN_NUMBER,
            TVRTAXD_TAX_AMOUNT
        from TVRTAXD
            )
            Select
                       B.TBRACCD_PIDM pidm,
                         e.matricula,
                        e.estatus_code,
                       e.estatus,
                       e.campus,
                        e.nivel,
                        e.programa,
                        e.desc_programa,
                        e.tipo,
                        e.clave_canal,
                        e.canal_final,
                        'Cargo' Tipo_Movimiento,
                        b.TBRACCD_AMOUNT Monto_Origen ,
                      b.tbraccd_balance Balance_Origen,
                      b.TBRACCD_DETAIL_CODE Codigo_Origen,
                      c.TBBDETC_DESC Descripcion_Origen ,
                      c.TBBDETC_DCAT_CODE Categoria_origen,
                      b.tbraccd_term_code Periodo_origen,
                      trunc (b.TBRACCD_EFFECTIVE_DATE) Fecha_Efectiva_origen,
                      b.TBRACCD_TRAN_NUMBER Seq_origen,
                      h.TVRTAXD_TAX_AMOUNT IVA,
                      'Relacion con Pagos -->' Dependencia,
                      a.monto Monto_pagado,
                      a.pago Seq_pagado,
                      d.codigo codigo_pagado,
                      d.descrip descripcion_pago,
                      trunc (d.fecha_pago) fecha_pagado,
                      null Vacio,
                      d.fecha_captura fecha_captura,
                      d.usuario_id usuario_id
            from tbraccd b, tbbdetc c, pagos_ppl a, pagos_ccd d, alumno e, IVA h
            Where b.tbraccd_detail_code in (select TBBDETC_DETAIL_CODE
                                                         from tbbdetc
                                                         where TBBDETC_DCAT_CODE in ('AAC', 'ABC', 'ACC', 'ACL', 'AJC',
                                                                                                         'APR', 'ARA', 'ARP', 'CCC', 'COL',
                                                                                                         'CSD', 'DAL', 'DEV', 'ENV', 'INS', 'INT', 'INU',
                                                                                                         'OTG', 'PYG', 'SEG', 'SER',
                                                                                                          'TAX', 'TUI', 'VTA')
                                                        And substr (TBBDETC_DETAIL_CODE, 1, 2 )  = substr (tbraccd_term_code, 1, 2)
                                                        and TBBDETC_DETC_ACTIVE_IND = 'Y'
                                                         )
            And b.tbraccd_amount >0
            And b.tbraccd_detail_code = c.TBBDETC_DETAIL_CODE
            and b.tbraccd_pidm = a.pidm  (+)
            And b.TBRACCD_TRAN_NUMBER = a.cargo  (+)
            And b.tbraccd_pidm = d.pidm  (+)
         --*--   And b.TBRACCD_TRAN_NUMBER = d.seq_pago (+)
            and a.pago = d.seq_pago (+)
            And b.tbraccd_pidm = e.pidm (+)
            And b.TBRACCD_PIDM = h.TVRTAXD_PIDM (+)
            And b.TBRACCD_TRAN_NUMBER = h.TVRTAXD_ACCD_TRAN_NUMBER (+)
         --   and b.tbraccd_pidm = 32602
union
            Select
                        B.TBRACCD_PIDM pidm,
                        e.matricula,
                        e.estatus_code,
                       e.estatus,
                       e.campus,
                        e.nivel,
                        e.programa,
                        e.desc_programa,
                        e.tipo,
                        e.clave_canal,
                        e.canal_final,
                         'Pago' Tipo_Movimiento,
                        b.TBRACCD_AMOUNT Monto_origen,
                      b.tbraccd_balance Balance_origen,
                      b.TBRACCD_DETAIL_CODE codigo_origen,
                      c.TBBDETC_DESC Descripcion_Origen,
                     c.TBBDETC_DCAT_CODE Categoria_origen,
                     b.tbraccd_term_code Periodo_origen,
                     trunc (b.TBRACCD_TRANS_DATE) Fecha_Efectiva_origen,
                      b.TBRACCD_TRAN_NUMBER Seq_origen,
                      null Vacio,
                      'Relacion con Cargos -->' Dependencia,
                      a.monto Monto_vinculado,
                      a.cargo Seq_vinculado,
                      d.codigo codigo_vinculado,
                      d.descrip descripcion_vinculado,
                      trunc (d.fecha_pago) fecha_Efectiva_vinculado,
                      h.TVRTAXD_TAX_AMOUNT IVA,
                      d.fecha_captura fecha_captura,
                      d.usuario_id usuario_id
            from tbraccd b, tbbdetc c, pagos_ppl a, pagos_ccd d,  alumno e, IVA h
            Where b.tbraccd_detail_code in (select TBBDETC_DETAIL_CODE
                                                         from tbbdetc
                                                         where TBBDETC_DCAT_CODE in ('AJT', 'APF', 'BEC', 'BEI', 'CAN', 'CDN', 'CNT', 'CON', 'CSH', 'CXC', 'DEP', 'DIP', 'DPA', 'DSC', 'DSI', 'DSP', 'EXC', 'INA', 'INC', 'ITR',
                                                                                                          'LPC', 'MSC', 'PPL', 'RET', 'RFD', 'RFI')
                                                        And (substr (TBBDETC_DETAIL_CODE, 1, 2 )  = substr (tbraccd_term_code, 1, 2) or TBBDETC_DETAIL_CODE = 'PLPA')
                                                        and TBBDETC_DETC_ACTIVE_IND = 'Y'
                                                         )
            And b.tbraccd_amount is not null
            And b.tbraccd_detail_code = c.TBBDETC_DETAIL_CODE
            and b.tbraccd_pidm = a.pidm  (+)
            And b.TBRACCD_TRAN_NUMBER = a.pago  (+)
            And b.tbraccd_pidm = d.pidm (+)
            And a.cargo = d.seq_pago (+)
            And b.tbraccd_pidm = e.pidm  (+)
            And b.TBRACCD_PIDM = h.TVRTAXD_PIDM (+)
            And b.TBRACCD_TRAN_NUMBER = h.TVRTAXD_ACCD_TRAN_NUMBER (+)
           -- and b.tbraccd_pidm = 32602
            order by 4, 5, 1, 17, 18

          )loop

                      Insert into TZTCRTE values (cartera.pidm,
                                                               cartera.matricula,
                                                                cartera.campus,
                                                                cartera.nivel,
                                                                cartera.estatus_code,
                                                                cartera.estatus,
                                                                cartera.programa,
                                                                cartera.desc_programa,
                                                                cartera.tipo,
                                                                cartera.clave_canal,
                                                                cartera.canal_final,
                                                                cartera.Tipo_Movimiento,
                                                                cartera.Monto_origen,
                                                                cartera.Balance_origen,
                                                                cartera.codigo_origen,
                                                                cartera.Descripcion_Origen,
                                                                cartera.Categoria_origen,
                                                                cartera.Periodo_origen,
                                                                cartera.Fecha_Efectiva_origen,
                                                                cartera.Seq_origen,
                                                                cartera.IVa,
                                                                cartera.Dependencia,
                                                                cartera.Monto_pagado,
                                                                cartera.Seq_pagado,
                                                                cartera.codigo_pagado,
                                                                cartera.descripcion_pago,
                                                                cartera.fecha_pagado,
                                                                cartera.vacio,
                                                                cartera.fecha_captura,
                                                                cartera.usuario_id,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                'Cartera_Relacion_cargo_cargo'
                                                                );
              commit;
          End Loop;
         commit;
        End;

  END;

Procedure sp_pagos_facturacion is

Begin

        Begin
            delete TZTCRTE
            where TZTCRTE_TIPO_REPORTE in ( 'Pago_Facturacion', 'Facturacion');
            Commit;
        Exception
        When others then
           null;
        End;

        Begin
                For c in (

                    with colegiatura as (
                        Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbraccd_desc desc_cargo, TBBDETC_DCAT_CODE Categ_Col
                        from tbraccd a, tbbdetc b
                        where a.tbraccd_detail_code = tbbdetc_detail_code
                        ),
        curp as (select GORADID_PIDM PIDM,
                        GORADID_ADDITIONAL_ID CURP
                     from GORADID
                     where GORADID_ADID_CODE = 'CURP')
                        select DISTINCT
                           tbraccd_pidm pidm ,
                          spriden_id as Matricula,
                          s.SPREMRG_LAST_NAME as Nombre,
                          saradap_camp_code as Campus,
                          SARADAP_LEVL_CODE as Nivel,
                          s.SPREMRG_MI as RFC,
                          s.SPREMRG_STREET_LINE1 || ' ' ||s.SPREMRG_STREET_LINE2 || ' ' ||s.SPREMRG_STREET_LINE3 as Dom_Fiscal,
                          s.SPREMRG_CITY as Ciudad,
                          s.SPREMRG_ZIP as CP,
                          s.SPREMRG_NATN_CODE as Pais,
                          tbraccd_detail_code as Tipo_Deposito,
                          tbraccd_desc as Descripcion,
                          tbraccd_amount as Monto,
                          TBRACCD_TRAN_NUMBER as Transaccion,
                         trunc ( TBRACCD_TRANS_DATE) as Fecha_Pago,
                          GORADID_ADDITIONAL_ID as REFERENCIA,
                          GORADID_ADID_CODE as Referencia_Tipo,
                          GOREMAL_EMAIL_ADDRESS as EMAIL,
                          nvl (TBRAPPL_AMOUNT,tbraccd_amount)  as Monto_pagado,
                          nvl (TBRAPPL_CHG_TRAN_NUMBER,TBRACCD_TRAN_NUMBER)  as secuencia_pago,
                          colegiatura.desc_cargo descripcion_pago,
                          colegiatura.Categ_Col,
                          max (s.SPREMRG_PRIORITY)  Prioridad,
                          curp.CURP,
                          SARADAP_DEGC_CODE_1 Grado,
                          s.SPREMRG_LAST_NAME Razon_social,
                          SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME Nombre_alumno,
                          SARADAP_PROGRAM_1 Programa,
                          SZTDTEC_NUM_RVOE RVOE_num,
                          SZTDTEC_CLVE_RVOE RVOE_clave
                        from SPREMRG s
                        left join SPRIDEN on s.SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
                        left join TBRACCD on s.SPREMRG_PIDM = TBRACCD_PIDM
                        left join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                        join SARADAP on s.SPREMRG_PIDM = SARADAP_PIDM
                        join SZTDTEC on saradap_camp_code = SZTDTEC_CAMP_CODE
                            and SARADAP_PROGRAM_1 = SZTDTEC_PROGRAM
                            and SARADAP_TERM_CODE_CTLG_1 = SZTDTEC_TERM_CODE
                        left join GORADID on s.SPREMRG_PIDM = GORADID_PIDM and GORADID_ADID_CODE in ('REFH','REFS')
                        left join GOREMAL on s.SPREMRG_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                        left outer join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                        left outer join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                        left outer join curp on SPRIDEN_PIDM = curp.PIDM
                        where
                          s.SPREMRG_MI is not NULL
                         -- And SPREMRG_pidm = 40684
                          and TBBDETC_TYPE_IND = 'P'
                          and TBBDETC_DCAT_CODE = 'CSH'
                          and to_number (s.SPREMRG_PRIORITY) in (select max(to_number (s1.SPREMRG_PRIORITY))
                                                                    FROM SPREMRG s1
                                                                    where s.SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                                        --and SPREMRG_PRIORITY = s1.SPREMRG_PRIORITY
                                                                        )
                        and SARADAP_APST_CODE = 'A'
                        GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, saradap_camp_code, SARADAP_LEVL_CODE, SPREMRG_MI,
                                        SPREMRG_STREET_LINE1 || ' ' ||SPREMRG_STREET_LINE2 || ' ' || SPREMRG_STREET_LINE3, SPREMRG_CITY, SPREMRG_ZIP, SPREMRG_NATN_CODE,
                                        tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, trunc ( TBRACCD_TRANS_DATE), GORADID_ADDITIONAL_ID,
                                        GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                        curp.CURP, SARADAP_DEGC_CODE_1, SPRIDEN_LAST_NAME, SPRIDEN_FIRST_NAME, SARADAP_PROGRAM_1, SZTDTEC_NUM_RVOE, SZTDTEC_CLVE_RVOE
                      ) loop

                      Insert into TZTCRTE values (c.pidm,
                                                               c.matricula,
                                                                c.campus,
                                                                c.nivel,
                                                                c.nombre,
                                                                c.rfc,
                                                                c.dom_fiscal,
                                                                c.ciudad,
                                                                c.cp,
                                                                c.pais,
                                                                c.tipo_deposito,
                                                                c.descripcion,
                                                                c.monto,
                                                                c.transaccion,
                                                                c.fecha_pago,
                                                                c.referencia,
                                                                c.referencia_tipo,
                                                                c.email,
                                                                c.monto_pagado,
                                                                c.secuencia_pago,
                                                                c.descripcion_pago,
                                                                c.Categ_Col,
                                                                c.Prioridad,
                                                                c.CURP,
                                                                c.Grado,
                                                                c.Razon_social,
                                                                c.Nombre_alumno,
                                                                c.Programa,
                                                                c.RVOE_num,
                                                                c.RVOE_clave,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                'Pago_Facturacion'
                                                                );




                End Loop;
        Commit;

             For c in (
                                with intereses as (
                                select distinct
                                TZTCRTE_PIDM Pidm,
                                TZTCRTE_LEVL as Nivel,
                                TZTCRTE_CAMP as Campus,
                                TZTCRTE_CAMPO11  as Fecha_Pago,
                                TZTCRTE_CAMPO17 as Intereses,
                                sum (TZTCRTE_CAMPO15) as Monto_intereses,
                                TZTCRTE_CAMPO18 as Categoria,
                                TZTCRTE_CAMPO10 as Secuencia
                                from TZTCRTE
                                where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
                                and TZTCRTE_CAMPO18 = 'INT'
                                group by
                                          TZTCRTE_PIDM,
                                          TZTCRTE_LEVL,
                                          TZTCRTE_CAMP,
                                          TZTCRTE_CAMPO11,
                                          TZTCRTE_CAMPO17,
                                          TZTCRTE_CAMPO18,
                                          TZTCRTE_CAMPO10
                                ),
                                accesorios as (
                                select distinct
                                          TZTCRTE_PIDM Pidm,
                                          TZTCRTE_LEVL as Nivel,
                                          TZTCRTE_CAMP as Campus,
                                          TZTCRTE_CAMPO11  as Fecha_Pago,
                                          TZTCRTE_CAMPO17 as accesorios,
                                          sum (TZTCRTE_CAMPO15) as Monto_accesorios,
                                          TZTCRTE_CAMPO18 as Categoria,
                                          TZTCRTE_CAMPO10 as Secuencia
                                from TZTCRTE
                                where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
                                and TZTCRTE_CAMPO18 in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                                group by
                                          TZTCRTE_PIDM,
                                          TZTCRTE_LEVL,
                                          TZTCRTE_CAMP,
                                          TZTCRTE_CAMPO11,
                                          TZTCRTE_CAMPO17,
                                          TZTCRTE_CAMPO18,
                                          TZTCRTE_CAMPO10
                                ),
                                colegiatura as (
                                select distinct
                                          TZTCRTE_PIDM Pidm,
                                          TZTCRTE_LEVL as Nivel,
                                          TZTCRTE_CAMP as Campus,
                                          TZTCRTE_CAMPO11  as Fecha_Pago,
                                          TZTCRTE_CAMPO17 as colegiatura,
                                          sum (TZTCRTE_CAMPO15) as Monto_colegiatura,
                                          TZTCRTE_CAMPO18 as Categoria,
                                          TZTCRTE_CAMPO10 as Secuencia
                                from TZTCRTE
                                where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
                                and TZTCRTE_CAMPO18 in  ('COL')
                                group by
                                          TZTCRTE_PIDM,
                                          TZTCRTE_LEVL,
                                          TZTCRTE_CAMP,
                                          TZTCRTE_CAMPO11,
                                          TZTCRTE_CAMPO17,
                                          TZTCRTE_CAMPO18,
                                          TZTCRTE_CAMPO10
                                ),
                                otros as (
                                select distinct
                                          TZTCRTE_PIDM Pidm,
                                          TZTCRTE_LEVL as Nivel,
                                          TZTCRTE_CAMP as Campus,
                                          TZTCRTE_CAMPO11  as Fecha_Pago,
                                          TZTCRTE_CAMPO17 as otros,
                                          sum (TZTCRTE_CAMPO15) as Monto_otros,
                                          TZTCRTE_CAMPO18 as Categoria,
                                          TZTCRTE_CAMPO10 as Secuencia
                                from TZTCRTE
                                where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
                                and TZTCRTE_CAMPO18 not in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL', 'VTA', 'TUI')
                                group by
                                          TZTCRTE_PIDM,
                                          TZTCRTE_LEVL,
                                          TZTCRTE_CAMP,
                                          TZTCRTE_CAMPO11,
                                          TZTCRTE_CAMPO17,
                                          TZTCRTE_CAMPO18,
                                          TZTCRTE_CAMPO10
                                )
                                select distinct
                                          TZTCRTE_pidm as pidm,
                                          TZTCRTE_CAMPO1 as Nombre,
                                          TZTCRTE_CAMPO2 as RFC,
                                          TZTCRTE_CAMPO3 as Dom_Fiscal,
                                          TZTCRTE_CAMPO4 as Ciudad,
                                          TZTCRTE_CAMPO5 as CP,
                                          TZTCRTE_CAMPO6 as Pais,
                                          TZTCRTE_CAMPO7 as Tipo_Deposito,
                                          TZTCRTE_CAMPO8 as Descripcion,
                                          TZTCRTE_CAMPO9 as Monto,
                                          TZTCRTE_LEVL as Nivel,
                                          TZTCRTE_CAMP as Campus,
                                          TZTCRTE_ID as Matricula,
                                          TZTCRTE_CAMPO10  as Transaccion,
                                          TZTCRTE_CAMPO11  as Fecha_Pago,
                                          TZTCRTE_CAMPO12 as REFERENCIA,
                                          TZTCRTE_CAMPO13 as Referencia_Tipo,
                                          TZTCRTE_CAMPO14  as EMAIL,
                                           e.Colegiatura,
                                          e.Monto_colegiatura,
                                          b.intereses,
                                          b.Monto_intereses,
                                          c.accesorios,
                                          c.Monto_accesorios,
                                          d.otros,
                                          d.monto_otros,
                                          TZTCRTE_CAMPO20 as Curp,
                                          TZTCRTE_CAMPO21 as Grado,
                                          TZTCRTE_CAMPO22 as Razon_social,
                                          TZTCRTE_CAMPO23 as Nombre_alumno,
                                          TZTCRTE_CAMPO24 as Programa,
                                          TZTCRTE_CAMPO25 as RVOE_num,
                                          TZTCRTE_CAMPO26 as RVOE_clave
                                from TZTCRTE, intereses b, accesorios c, otros d, colegiatura e
                                where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
                                     --and TZTCRTE_CAMP = :MC_CAMPUS
                                     --and TZTCRTE_LEVL = :MC_NIVEL
                                --and to_date(TZTCRTE_CAMPO11,'dd/mm/rrrr') BETWEEN to_date(:Fecha_Inicio, 'dd/mm/rrrr') and to_date(:Fecha_Fin, 'dd/mm/rrrr')
                                --And TZTCRTE_ID = '010041922'
                                and TZTCRTE_CAMPO18 in ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL')
                               --and TZTCRTE_CAMPO18 = 'COL' (+)
                              and TZTCRTE_PIDM = e.pidm (+)
                                and TZTCRTE_LEVL = e.nivel (+)
                                and TZTCRTE_CAMP = e.campus (+)
                                and TZTCRTE_CAMPO11 = e.Fecha_Pago (+)
                                And TZTCRTE_CAMPO10 = e.secuencia (+)
                                and TZTCRTE_PIDM = b.pidm (+)
                                and TZTCRTE_LEVL = b.nivel (+)
                                and TZTCRTE_CAMP = b.campus (+)
                                and TZTCRTE_CAMPO11 = b.Fecha_Pago (+)
                                And TZTCRTE_CAMPO10 = b.secuencia (+)
                                and TZTCRTE_PIDM = c.pidm (+)
                                and TZTCRTE_LEVL = c.nivel (+)
                                and TZTCRTE_CAMP = c.campus (+)
                                and TZTCRTE_CAMPO11 = c.Fecha_Pago (+)
                                And TZTCRTE_CAMPO10 = c.secuencia (+)
                                and TZTCRTE_PIDM = d.pidm (+)
                                and TZTCRTE_LEVL = d.nivel (+)
                                and TZTCRTE_CAMP = d.campus (+)
                                and TZTCRTE_CAMPO11 = d.Fecha_Pago (+)
                                And TZTCRTE_CAMPO10 = d.secuencia (+)
                                --and TZTCRTE_PIDM = 16589
                                group by TZTCRTE_pidm,
                                            TZTCRTE_CAMPO1,
                                          TZTCRTE_CAMPO2,
                                          TZTCRTE_CAMPO3,
                                          TZTCRTE_CAMPO4,
                                          TZTCRTE_CAMPO5,
                                          TZTCRTE_CAMPO6,
                                          TZTCRTE_CAMPO7,
                                          TZTCRTE_CAMPO8,
                                          TZTCRTE_CAMPO9,
                                          TZTCRTE_LEVL,
                                          TZTCRTE_CAMP,
                                          TZTCRTE_ID,
                                          TZTCRTE_CAMPO10,
                                          TZTCRTE_CAMPO11,
                                          TZTCRTE_CAMPO12,
                                          TZTCRTE_CAMPO13,
                                          TZTCRTE_CAMPO14,
                                          e.Colegiatura,
                                          e.Monto_colegiatura,
                                          b.intereses,
                                          b.Monto_intereses,
                                          c.accesorios,
                                          c.Monto_accesorios,
                                          d.otros,
                                          d.monto_otros,
                                          TZTCRTE_CAMPO20,
                                          TZTCRTE_CAMPO21,
                                          TZTCRTE_CAMPO22,
                                          TZTCRTE_CAMPO23,
                                          TZTCRTE_CAMPO24,
                                          TZTCRTE_CAMPO25,
                                          TZTCRTE_CAMPO26
                                order by TZTCRTE_ID, TZTCRTE_CAMPO11, TZTCRTE_CAMPO10 ) loop

                              Insert into TZTCRTE values (c.pidm,
                                                               c.matricula,--
                                                                c.campus,--
                                                                c.nivel,--
                                                                c.nombre,--
                                                                c.rfc,--
                                                                c.dom_fiscal,--
                                                                c.ciudad, --
                                                                c.cp, --
                                                                c.pais,--
                                                                c.tipo_deposito,--
                                                                c.descripcion,--
                                                                c.monto,--
                                                                c.transaccion,--
                                                                c.fecha_pago,--
                                                                c.referencia,--
                                                                c.referencia_tipo,--
                                                                c.email,--
                                                                c.colegiatura,
                                                                c.monto_colegiatura,
                                                                c.intereses,
                                                                c.monto_intereses,
                                                                c.accesorios,
                                                                c.monto_accesorios,
                                                                c.otros,
                                                                c.monto_otros,
                                                                c.CURP,
                                                                c.Grado,
                                                                c.Razon_social,
                                                                c.Nombre_alumno,
                                                                c.Programa,
                                                                c.RVOE_num,
                                                                c.RVOE_clave,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                'Facturacion'
                                                                );

            End loop;


        End;

End sp_pagos_facturacion;

PROCEDURE sp_detallealumnos

is

    Begin

        delete SZTHIST;
        commit;

            For alumno in (
                                    select distinct b.spriden_id  ID, a.SORLCUR_PIDM pidm, a.SORLCUR_LMOD_CODE lmod_code, a.SORLCUR_KEY_SEQNO seqno, a.sorlcur_program programa,
                                                        a.sorlcur_levl_code nivel, a.sorlcur_camp_code campus, SORLCUR_TERM_CODE_ADMIT Periodo_Matric, a.SORLCUR_ROLL_IND roll_ind, a.SORLCUR_CACT_CODE cact_code,
                                                        a.SORLCUR_TERM_CODE_CTLG term_code_ctlg,
                                                        (select pkg_datos_academicos.avance1(b.spriden_pidm, a.sorlcur_program) from dual) avance,
                                                        (select pkg_datos_academicos.promedio1(b.spriden_pidm, a.sorlcur_program) from dual) promedio,
                                                       0 avance_1,
                                                       0 promedio_1,
                                                       (select pkg_datos_academicos.total_mate(a.sorlcur_program, b.spriden_pidm) from dual)  total_materia,
                                                       trunc (a.SORLCUR_ACTIVITY_DATE) FECHA_MOV
                                    from sorlcur a, spriden b
                                    where a.SORLCUR_LMOD_CODE = 'LEARNER'
                                    and a.SORLCUR_SEQNO = (select min (a1.SORLCUR_SEQNO)
                                                                            from SORLCUR a1
                                                                            Where a.sorlcur_pidm = a1.sorlcur_pidm
                                                                            And a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE
                                                                            And  a.sorlcur_program = a1.sorlcur_program)
                                    and a.sorlcur_pidm = b.spriden_pidm
                                    and b.SPRIDEN_CHANGE_IND is null

                  ) loop


                                    For materia in (
                                                                            select COUNT (*)numero , SSBSECT_TERM_CODE periodo,  SSBSECT_PTRM_CODE pperiodo, SSBSECT_PTRM_START_DATE fecha_inicio, SFRSTCR_pidm pidm
                                                                                        from SFRSTCR, SSBSECT
                                                                                        where SFRSTCR_pidm = alumno.pidm
                                                                                        and SFRSTCR_STSP_KEY_SEQUENCE = alumno.seqno
                                                                                        And SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                                                                                        And SFRSTCR_CRN = SSBSECT_CRN
                                                                                        group by SSBSECT_TERM_CODE, SSBSECT_PTRM_CODE,  SSBSECT_PTRM_START_DATE, SFRSTCR_pidm
                                                                                  order by 2, 3

                                      ) loop

                                                                Begin
                                                                          Insert into SZTHIST values ( alumno.pidm,
                                                                                                                    alumno.id,
                                                                                                                    alumno.campus,
                                                                                                                    alumno.nivel,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    alumno.programa,
                                                                                                                    materia.periodo,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    materia.pperiodo,
                                                                                                                    materia.fecha_inicio,
                                                                                                                    nvl (alumno.Periodo_Matric, materia.periodo),
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    alumno.seqno,
                                                                                                                    null,
                                                                                                                    alumno.avance,
                                                                                                                    alumno.promedio,
                                                                                                                    alumno.fecha_mov,
                                                                                                                    NULL,
                                                                                                                    alumno.total_materia,
                                                                                                                    alumno.term_code_ctlg,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null
                                                                                                                    );
                                                                             Commit;
                                                                Exception
                                                                    When Others then
                                                                      null;
                                                                End;
                                      End loop materia;


                                      For materia_st in (
                                        select distinct COUNT (*)numero , SSBSECT_TERM_CODE periodo,  SSBSECT_PTRM_CODE pperiodo, SSBSECT_PTRM_START_DATE fecha_inicio,
                                                                    case when SFRSTCR_RSTS_CODE = 'RE' then
                                                                                'Inscritas'
                                                                    end  as Altas,
                                                                    case when SFRSTCR_RSTS_CODE != 'RE' then
                                                                                'Bajas'
                                                                    end  as baja
                                                                                        from SFRSTCR, SSBSECT
                                                                                        where SFRSTCR_pidm = alumno.pidm
                                                                                        and SFRSTCR_STSP_KEY_SEQUENCE = alumno.seqno
                                                                                        And SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
                                                                                        And SFRSTCR_CRN = SSBSECT_CRN
                                                                                        group by SSBSECT_TERM_CODE, SSBSECT_PTRM_CODE,  SSBSECT_PTRM_START_DATE,SFRSTCR_RSTS_CODE
                                                                                        order by 2,4  )
                                      loop
                                                                If   materia_st.Altas is not null  then
                                                                        Begin
                                                                                Update SZTHIST
                                                                                set SZTHIST_MATERIAS_AC = materia_st.numero,
                                                                                      SZTHIST_STST_CODE = 'MA'
                                                                                where SZTHIST_PIDM = alumno.pidm
                                                                                And  SZTHIST_PROGRAM =  alumno.programa
                                                                                And SZTHIST_TERM_CODE = materia_st.periodo
                                                                                And SZTHIST_PTRM_CODE = materia_st.pperiodo;
                                                                        End;

                                                                Elsif  materia_st.baja is not null    then
                                                                        Begin
                                                                                Update SZTHIST
                                                                                set SZTHIST_MATERIAS_bj = materia_st.numero
                                                                                where SZTHIST_PIDM = alumno.pidm
                                                                                And  SZTHIST_PROGRAM =  alumno.programa
                                                                                And SZTHIST_TERM_CODE = materia_st.periodo
                                                                                And SZTHIST_PTRM_CODE = materia_st.pperiodo;
                                                                        End;
                                                                End if;

                                      End Loop materia_st;

                                     Begin
                                       update SZTHIST a
                                      set a.SZTHIST_STYP_CODE = 'N'
                                      where a.SZTHIST_PIDM = alumno.pidm
                                      And a.SZTHIST_CAMP_CODE =  alumno.campus
                                      And a.SZTHIST_LEVL_CODE = alumno.nivel
                                      And a.SZTHIST_PROGRAM =  alumno.programa
                                      and a.SZTHIST_TERM_CODE = (select min (a1.SZTHIST_TERM_CODE)
                                                                                     from SZTHIST a1
                                                                                     where a.SZTHIST_PIDM = a1.SZTHIST_PIDM
                                                                                      And a.SZTHIST_CAMP_CODE = a1.SZTHIST_CAMP_CODE
                                                                                      And a.SZTHIST_LEVL_CODE = a1.SZTHIST_LEVL_CODE
                                                                                      And a.SZTHIST_PROGRAM = a1.SZTHIST_PROGRAM);
                                     Commit;
                                     Exception
                                     When Others then
                                        null;
                                     End;


                                     Begin
                                       update SZTHIST a
                                      set a.SZTHIST_STYP_CODE = 'C'
                                      where a.SZTHIST_PIDM = alumno.pidm
                                      And a.SZTHIST_CAMP_CODE =  alumno.campus
                                      And a.SZTHIST_LEVL_CODE = alumno.nivel
                                      And a.SZTHIST_PROGRAM =  alumno.programa
                                      And SZTHIST_STYP_CODE is null;

                                       Commit;
                                     Exception
                                     When Others then
                                        null;
                                     End;


                                    for bajas in  ( select distinct a.SZTHIST_TERM_CODE,  sum (a.SZTHIST_MATERIAS_BJ) baja
                                                    from SZTHIST a
                                                  where a.SZTHIST_PIDM = alumno.pidm
                                                  And a.SZTHIST_CAMP_CODE = alumno.campus
                                                  And a.SZTHIST_LEVL_CODE = alumno.nivel
                                                  And a.SZTHIST_PROGRAM =  alumno.programa
                                                 And a.SZTHIST_STST_CODE is null
                                                    group by a.SZTHIST_TERM_CODE
                                                    order by 1 asc )
                                    loop


                                               If bajas.baja >= 1 then
                                                    null;

                                                         Begin
                                                           update SZTHIST a
                                                          set a.SZTHIST_STST_CODE = 'BI'
                                                          where a.SZTHIST_PIDM = alumno.pidm
                                                          And a.SZTHIST_CAMP_CODE =  alumno.campus
                                                          And a.SZTHIST_LEVL_CODE = alumno.nivel
                                                          And a.SZTHIST_PROGRAM =  alumno.programa
                                                           And a.SZTHIST_STST_CODE is null;
                                                           Commit;
                                                         Exception
                                                         When Others then
                                                            null;
                                                         End;

                                               End if;
                                               Commit;
                                    End loop bajas;


                                    for alta  in (

                                    select distinct SZTHIST_TERM_CODE,  sum (SZTHIST_MATERIAS_AC) altas
                                                    from SZTHIST a
                                                  where a.SZTHIST_PIDM = alumno.pidm
                                                  And a.SZTHIST_CAMP_CODE = alumno.campus
                                                  And a.SZTHIST_LEVL_CODE = alumno.nivel
                                                  And a.SZTHIST_PROGRAM =  alumno.programa
                                                  And a.SZTHIST_STST_CODE is null
                                                    group by SZTHIST_TERM_CODE
                                                    order by 1 asc

                                    ) loop

                                               If alta.altas >= 1 then

                                                         Begin
                                                           update SZTHIST a
                                                          set a.SZTHIST_STST_CODE = 'MA'
                                                          where a.SZTHIST_PIDM = alumno.pidm
                                                          And a.SZTHIST_CAMP_CODE =  alumno.campus
                                                          And a.SZTHIST_LEVL_CODE = alumno.nivel
                                                          And a.SZTHIST_PROGRAM =  alumno.programa
                                                           And a.SZTHIST_STST_CODE is null;
                                                           Commit;
                                                         Exception
                                                         When Others then
                                                            null;
                                                         End;

                                               End if;
                                               Commit;
                                    End loop alta;


                                   -------------------- Registra el Canal de Venta  ----------------------
                                   For canal in (Select distinct SARACMT_COMMENT_TEXT canal
                                                        from saracmt
                                                        where SARACMT_PIDM = alumno.pidm
                                                        And SARACMT_APPL_NO = alumno.seqno
                                                        And SARACMT_ORIG_CODE = 'CANF' )
                                 Loop

                                                     Update SZTHIST
                                                     set SZTHIST_CANAL = canal.canal
                                                     Where SZTHIST_PIDM = alumno.pidm
                                                     And  SZTHIST_KEY_SEQNO = alumno.seqno;
                                 End Loop canal;

                                      -------------------- Registra el vendedor  ----------------------
                                   For vendedor in (Select distinct SARACMT_COMMENT_TEXT vendedor
                                                        from saracmt
                                                        where SARACMT_PIDM = alumno.pidm
                                                        And SARACMT_APPL_NO = alumno.seqno
                                                        And SARACMT_ORIG_CODE = 'VENF' )
                                 Loop

                                                     Update SZTHIST
                                                     set SZTHIST_VENDEDOR = vendedor.vendedor
                                                     Where SZTHIST_PIDM = alumno.pidm
                                                     And  SZTHIST_KEY_SEQNO = alumno.seqno;
                                 End Loop vendedor;





                  End loop alumno;

                 Commit;



                For alumno_no in (

                select distinct b.spriden_id  ID, a.SORLCUR_PIDM pidm, a.SORLCUR_LMOD_CODE , a.SORLCUR_KEY_SEQNO study, a.sorlcur_program programa,
                                                        a.sorlcur_levl_code nivel, a.sorlcur_camp_code campus , SORLCUR_START_DATE fecha_inicio, SORLCUR_TERM_CODE_MATRIC Periodo_Matric,
                                                        a.SORLCUR_TERM_CODE_CTLG,
                                                        (select pkg_datos_academicos.avance1(b.spriden_pidm, a.sorlcur_program) from dual) avance,
                                                        (select pkg_datos_academicos.promedio1(b.spriden_pidm, a.sorlcur_program) from dual) promedio,
                                                       null avance_1,
                                                       null promedio_1,
                                                       (select pkg_datos_academicos.total_mate(a.sorlcur_program, b.spriden_pidm) from dual) total_materia,
                                                       trunc (a.SORLCUR_ACTIVITY_DATE) FECHA_MOV
                                    from sorlcur a, spriden b
                                    where a.SORLCUR_LMOD_CODE = 'LEARNER'
                                    and a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
                                                                            from SORLCUR a1
                                                                            Where a.sorlcur_pidm = a1.sorlcur_pidm
                                                                            And a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE
                                                                            And  a.sorlcur_program = a1.sorlcur_program)
                                    and a.sorlcur_pidm = b.spriden_pidm
                                    and b.SPRIDEN_CHANGE_IND is null
                                    And  a.SORLCUR_PIDM not in (select SZTHIST_pidm
                                                                                from SZTHIST
                                                                                Where SZTHIST_CAMP_CODE = a.sorlcur_camp_code
                                                                                And SZTHIST_LEVL_CODE = a.sorlcur_levl_code
                                                                                And SZTHIST_PROGRAM = a.sorlcur_program
                                                                                )
                                    order by 1

            ) loop


                                    For estatus in (

                                    select a.SGBSTDN_PIDM Pidm , b.spriden_id Id, a.SGBSTDN_CAMP_CODE campus, a.SGBSTDN_LEVL_CODE nivel, SGBSTDN_STST_CODE Estatus,
                                                                   a.SGBSTDN_STYP_CODE Tipo, a.SGBSTDN_PROGRAM_1 Programa,
                                                                   a.SGBSTDN_TERM_CODE_EFF Periodo, a.SGBSTDN_TERM_CODE_ADMIT, a.sgbstdn_rate_code rate
                                                          from sgbstdn a, spriden b
                                                          where a.SGBSTDN_PIDM   = b.spriden_pidm
                                                          And SPRIDEN_CHANGE_IND is null
                                                          And a.SGBSTDN_PIDM    = alumno_no.pidm
                                                          And a.SGBSTDN_CAMP_CODE = alumno_no.campus
                                                          And a.SGBSTDN_LEVL_CODE = alumno_no.nivel
                                                          and a.SGBSTDN_PROGRAM_1 = alumno_no.programa
                                                          And a.SGBSTDN_TERM_CODE_EFF =(select max(a1.SGBSTDN_TERM_CODE_EFF)
                                                                                                                from SGBSTDN a1
                                                                                                                where  a.SGBSTDN_PIDM   = a1.SGBSTDN_PIDM
                                                                                                                  And a.SGBSTDN_CAMP_CODE = a1.SGBSTDN_CAMP_CODE
                                                                                                                  And a.SGBSTDN_LEVL_CODE = a1.SGBSTDN_LEVL_CODE
                                                                                                                  and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1)

                                    ) Loop


                                                                Begin
                                                                           Insert into SZTHIST values ( estatus.pidm,
                                                                                                                    estatus.id,
                                                                                                                    estatus.campus,
                                                                                                                    estatus.nivel,
                                                                                                                    estatus.estatus,
                                                                                                                    estatus.tipo,
                                                                                                                    estatus.programa,
                                                                                                                    estatus.periodo,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    alumno_no.fecha_inicio,
                                                                                                                    nvl (alumno_no.Periodo_Matric, estatus.periodo),
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    estatus.rate,
                                                                                                                    null,
                                                                                                                    alumno_no.study,
                                                                                                                    null,
                                                                                                                    alumno_no.avance,
                                                                                                                    alumno_no.promedio,
                                                                                                                    alumno_no.FECHA_MOV,
                                                                                                                    NULL,
                                                                                                                    alumno_no.total_materia,
                                                                                                                    alumno_no.SORLCUR_TERM_CODE_CTLG,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null,
                                                                                                                    null
                                                                                                                    );
                                                                             Commit;
                                                                Exception
                                                                    When Others then
                                                                      null;
                                                                End;
                                    End loop estatus;

                                   For canal in (Select distinct SARACMT_COMMENT_TEXT canal
                                                        from saracmt
                                                        where SARACMT_PIDM = alumno_no.pidm
                                                        And SARACMT_APPL_NO = alumno_no.study
                                                        And SARACMT_ORIG_CODE = 'CANF' )
                                 Loop

                                                     Update SZTHIST
                                                     set SZTHIST_CANAL = canal.canal
                                                     Where SZTHIST_PIDM = alumno_no.pidm
                                                     And  SZTHIST_KEY_SEQNO = alumno_no.study;
                                 End Loop canal;

                                                                    -------------------- Registra el vendedor  ----------------------
                                 For vendedor in (Select distinct SARACMT_COMMENT_TEXT vendedor
                                                        from saracmt
                                                        where SARACMT_PIDM = alumno_no.pidm
                                                        And SARACMT_APPL_NO = alumno_no.study
                                                        And SARACMT_ORIG_CODE = 'VENF' )
                                 Loop

                                                     Update SZTHIST
                                                     set SZTHIST_VENDEDOR = vendedor.vendedor
                                                     Where SZTHIST_PIDM = alumno_no.pidm
                                                     And  SZTHIST_KEY_SEQNO = alumno_no.study;
                                 End Loop vendedor;



                                    Commit;
            End loop alumno_no;


            for estatus_final in (

            select distinct a.SZTHIST_PIDM PIDM , b.SORLCUR_CACT_CODE ESTATUS, a.SZTHIST_PROGRAM PROGRAMA, SZTHIST_STST_CODE ESTATUS_ANT, trunc (SORLCUR_ACTIVITY_DATE) fecha_act, c.SGBSTDN_STST_CODE
                                            from SZTHIST a, sorlcur b, sgbstdn c
                                            where a.SZTHIST_PIDM = sorlcur_pidm
                                            and  b.SORLCUR_LMOD_CODE = 'LEARNER'
                                            And a.SZTHIST_PROGRAM = b.sorlcur_program
                                            and b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                                                                                    from SORLCUR b1
                                                                                                                    Where b.sorlcur_pidm = b1.sorlcur_pidm
                                                                                                                    And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                                                                                    And  b.sorlcur_program = b1.sorlcur_program)
                                           and b.sorlcur_pidm = c.sgbstdn_pidm
                                           And b.sorlcur_program = c.sgbstdn_program_1
                                           and c.sgbstdn_term_code_eff in (select max (c1.sgbstdn_term_code_eff)
                                                                                            from sgbstdn c1
                                                                                            where c.sgbstdn_pidm = c1.sgbstdn_pidm
                                                                                            And c.sgbstdn_program_1 = c1.sgbstdn_program_1)

            ) loop

                                        If  estatus_final.ESTATUS =  'INACTIVE' And  estatus_final.SGBSTDN_STST_CODE IN ('AS', 'PR', 'MA') Then
                                                Update SZTHIST a
                                                set  SZTHIST_STST_CODE = estatus_final.SGBSTDN_STST_CODE,
                                                     SZTHIST_MOVIMIENTO = estatus_final.fecha_act
                                                where a.SZTHIST_PIDM = estatus_final.PIDM
                                                And   SZTHIST_PROGRAM =  estatus_final.programa
                                                And SZTHIST_TERM_CODE = (select max (a1.SZTHIST_TERM_CODE)
                                                                                             from SZTHIST a1
                                                                                             where a.SZTHIST_PIDM = a1.SZTHIST_PIDM
                                                                                             And a.SZTHIST_PROGRAM = a1.SZTHIST_PROGRAM);
                                        ElsIf  estatus_final.ESTATUS =  'INACTIVE' And  estatus_final.SGBSTDN_STST_CODE not IN ('AS', 'PR', 'MA', 'EG') Then
                                                Update SZTHIST a
                                                set  SZTHIST_STST_CODE = estatus_final.SGBSTDN_STST_CODE,
                                                     SZTHIST_MOVIMIENTO = estatus_final.fecha_act
                                                where a.SZTHIST_PIDM = estatus_final.PIDM
                                                And   SZTHIST_PROGRAM =  estatus_final.programa
                                                And SZTHIST_TERM_CODE = (select max (a1.SZTHIST_TERM_CODE)
                                                                                             from SZTHIST a1
                                                                                             where a.SZTHIST_PIDM = a1.SZTHIST_PIDM
                                                                                             And a.SZTHIST_PROGRAM = a1.SZTHIST_PROGRAM);
                                        Elsif estatus_final.ESTATUS =  'ACTIVE' And  estatus_final.SGBSTDN_STST_CODE IN ('AS', 'PR', 'MA', 'EG') Then
                                                Update SZTHIST a
                                                set  SZTHIST_STST_CODE = estatus_final.SGBSTDN_STST_CODE,
                                                SZTHIST_MOVIMIENTO = estatus_final.fecha_act
                                                where a.SZTHIST_PIDM = estatus_final.PIDM
                                                And   SZTHIST_PROGRAM = estatus_final.programa
                                                And SZTHIST_TERM_CODE = (select max (a1.SZTHIST_TERM_CODE)
                                                                                             from SZTHIST a1
                                                                                             where a.SZTHIST_PIDM = a1.SZTHIST_PIDM
                                                                                             And a.SZTHIST_PROGRAM = a1.SZTHIST_PROGRAM);
                                        Elsif estatus_final.ESTATUS =  'ACTIVE' And  estatus_final.SGBSTDN_STST_CODE NOT IN ('AS', 'PR', 'MA', 'EG') Then
                                                Update SZTHIST a
                                                set  SZTHIST_STST_CODE = estatus_final.SGBSTDN_STST_CODE,
                                                    SZTHIST_MOVIMIENTO = estatus_final.fecha_act
                                                where a.SZTHIST_PIDM = estatus_final.PIDM
                                                And   SZTHIST_PROGRAM = estatus_final.programa
                                                And SZTHIST_TERM_CODE = (select max (a1.SZTHIST_TERM_CODE)
                                                                                             from SZTHIST a1
                                                                                             where a.SZTHIST_PIDM = a1.SZTHIST_PIDM
                                                                                             And a.SZTHIST_PROGRAM = a1.SZTHIST_PROGRAM);

                                        End if;
            Commit;
            End Loop estatus_final;

            For muestra in ( select distinct SZTHIST_PIDM pidm  , SZTHIST_CAMP_CODE campus, SZTHIST_LEVL_CODE nivel , SZTHIST_PROGRAM programa, SZTHIST_KEY_SEQNO study
                               from SZTHIST )
            loop
                                     For rate in (select distinct a.sgbstdn_rate_code rate, a.sgbstdn_pidm pidm, a.sgbstdn_camp_code campus, a.sgbstdn_levl_code nivel
                                              from sgbstdn a
                                              Where a.sgbstdn_pidm = muestra.pidm
                                              And  a.sgbstdn_camp_code = muestra.campus
                                              And a.sgbstdn_levl_code = muestra.nivel
                                              And a.sgbstdn_term_code_eff = (select max ( a1.sgbstdn_term_code_eff)
                                                                                               from sgbstdn a1
                                                                                               Where a.sgbstdn_pidm = a1.sgbstdn_pidm
                                                                                               And a.sgbstdn_levl_code = a1.sgbstdn_levl_code) )
                            loop

                                              Update SZTHIST
                                              set  SZTHIST_RATE_CODE = rate.rate
                                              where SZTHIST_PIDM = rate.pidm
                                              and SZTHIST_CAMP_CODE = rate.campus
                                              And SZTHIST_LEVL_CODE = rate.nivel;


                            End Loop rate;

                           for jornada in ( Select SGRSATT_ATTS_CODE Jornada, SGRSATT_PIDM pidm , SGRSATT_STSP_KEY_SEQUENCE study
                                                from SGRSATT
                                                Where  substr (SGRSATT_ATTS_CODE, 1,1) in ( '1', '2', '3', '4', '5', '6', '7', '8', '9')
                                                And SGRSATT_PIDM = muestra.pidm
                         ) loop


                                              Update SZTHIST
                                              set  SZTHIST_ATTS_CODE = Jornada.Jornada
                                              where SZTHIST_PIDM = jornada.pidm
                                              And  SZTHIST_KEY_SEQNO = jornada.study;

                         End Loop Jornada;

                          Commit;
            End Loop muestra;


    End;

Procedure sp_Academico_Financiero

is

    BEGIN

        Begin

            delete TZTCRTE
                where TZTCRTE_TIPO_REPORTE = 'Academico_Financiero';
                Commit;

            For acafin in (

            With correo_principal as (
            select Distinct
                GOREMAL_PIDM Pidm,
                GOREMAL_EMAIL_ADDRESS,
                max(GOREMAL_SURROGATE_ID)
            from GOREMAL
            Where goremal_emal_code='PRIN' and goremal_status_ind='A'
            group by GOREMAL_PIDM, GOREMAL_EMAIL_ADDRESS
            ),
            correo_alterno as (
            select Distinct
                GOREMAL_PIDM Pidm,
                GOREMAL_EMAIL_ADDRESS,
                max(GOREMAL_SURROGATE_ID)
            from GOREMAL
            Where goremal_emal_code='ALTE' and goremal_status_ind='A'
            group by GOREMAL_PIDM, GOREMAL_EMAIL_ADDRESS
            ),
            telefono_casa as (
            Select distinct
                SPRTELE_PIDM pidm,
                SPRTELE_PHONE_AREA || SPRTELE_PHONE_NUMBER Telefono,
                max(SPRTELE_SURROGATE_ID)
            from SPRTELE
            Where SPRTELE_TELE_CODE = 'RESI'
            group by SPRTELE_PIDM, SPRTELE_PHONE_AREA || SPRTELE_PHONE_NUMBER
            ),
            telefono_celular as (
            Select distinct
                SPRTELE_PIDM pidm,
                SPRTELE_PHONE_AREA || SPRTELE_PHONE_NUMBER Telefono,
                max(SPRTELE_SURROGATE_ID)
            from SPRTELE
            Where SPRTELE_TELE_CODE = 'CELU'
            group by SPRTELE_PIDM, SPRTELE_PHONE_AREA || SPRTELE_PHONE_NUMBER
            ),
            curricula as (
            Select
                a.sorlcur_pidm pidm,
                a.sorlcur_camp_code campus,
                a.sorlcur_levl_code Nivel_Code,
                b.STVLEVL_DESC nivel,
                a.sorlcur_program programa,
                a.SORLCUR_TERM_CODE_CTLG periodo_catalogo,
                c.SZTDTEC_PROGRAMA_COMP Nombre_Programa,
                max(a.SORLCUR_SURROGATE_ID)
            from sorlcur a, stvlevl b, sztdtec c
            where a.SORLCUR_LMOD_CODE = 'LEARNER'
                --And a.SORLCUR_CACT_CODE = 'ACTIVE'
                And b.stvlevl_code = a.sorlcur_levl_code
                And a.sorlcur_program = c.SZTDTEC_PROGRAM
                And a.SORLCUR_TERM_CODE_CTLG = c.SZTDTEC_TERM_CODE
                And a.SORLCUR_SEQNO in (select max (a1.SORLCUR_SEQNO)
                                                        from SORLCUR a1
                                                        Where a.sorlcur_pidm = a1.sorlcur_pidm
                                                        and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
            group by a.sorlcur_pidm, a.sorlcur_camp_code, a.sorlcur_levl_code, b.STVLEVL_DESC, a.sorlcur_program, a.SORLCUR_TERM_CODE_CTLG, c.SZTDTEC_PROGRAMA_COMP
            ),
            matricula as (
            Select
                a.sorlcur_pidm pidm,
                a.sorlcur_camp_code campus,
                a.sorlcur_levl_code nivel,
                a.sorlcur_program programa,
                a.SORLCUR_TERM_CODE_CTLG periodo_catalogo,
                max(a.SORLCUR_SURROGATE_ID)
            from sorlcur a
            where a.SORLCUR_LMOD_CODE = 'LEARNER'
                And a.SORLCUR_SEQNO in (select max (a1.SORLCUR_SEQNO)
                                                        from SORLCUR a1
                                                        Where a.sorlcur_pidm = a1.sorlcur_pidm
                                                        and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
            group by a.sorlcur_pidm, a.sorlcur_camp_code, a.sorlcur_levl_code, a.sorlcur_program, a.SORLCUR_TERM_CODE_CTLG
            ),
            Referencia as (
            select
                GORADID_PIDM PIDM,
                GORADID_ADDITIONAL_ID Referencia,
                max(GORADID_SURROGATE_ID)
            FROM GORADID
            where GORADID_ADID_CODE like 'REF%'
                group by GORADID_PIDM, GORADID_ADDITIONAL_ID
            ),
            Incobrable as (
            select distinct
            TZTMORA_PIDM PIDM,
            case
                when TZTMORA_dias between 1 and 30 then
                         .0
                when TZTMORA_dias between 31 and 60 then
                         .5
                when TZTMORA_dias between 61 and 90 then
                        .10
                when TZTMORA_dias between 91 and 120 then
                        .20
                when TZTMORA_dias between 121 and 150 then
                        .30
                when TZTMORA_dias between 151 and 180 then
                        .60
                when TZTMORA_dias > 180 then
                        .85
            End as Incobrable
            from TZTMORA)
            select distinct a.spriden_pidm usuario_id,
                                a.spriden_id Matricula,
                                f.campus Campus,
                                f.Nivel_Code Nivel_Code,
                                f.nivel Nivel_Academico,
                                a.SPRIDEN_LAST_NAME ||' '||SPRIDEN_FIRST_NAME Nombre,
                                b.GOREMAL_EMAIL_ADDRESS Correo_Principal,
                                c.GOREMAL_EMAIL_ADDRESS Correo_Alterno,
                                d.Telefono Telefono_Casa,
                                e.Telefono Telefono_Celular,
                                PKG_REPORTES_1.f_saldototal (a.spriden_pidm) Saldo_Total,
                                PKG_REPORTES_1.f_saldodia (a.spriden_pidm) Saldo_Vencido,
                                PKG_REPORTES_1.f_cargo_vencidos (a.spriden_pidm) Numero_Cargo_Vencido,
                                PKG_REPORTES_1.f_fecha_pago_vieja (a.spriden_pidm) Primer_fecha_limite_de_pago,
                                PKG_REPORTES_1.f_fecha_pago_alta (a.spriden_pidm) Ultima_fecha_limite_de_pago,
                                PKG_REPORTES_1.f_dias_atraso  (a.spriden_pidm) Dias_Atraso,
                                trunc (PKG_REPORTES_1.f_dias_atraso  (a.spriden_pidm) / 30 )  Meses_Atraso,
                                PKG_REPORTES_1.f_mora  (a.spriden_pidm) Mora,
                                PKG_REPORTES_1.f_cargo_total_futuro (a.spriden_pidm) Total_montos_Prox,
                                PKG_REPORTES_1.f_saldocorte (a.spriden_pidm) Saldo_Prox,
                                PKG_REPORTES_1.f_cargo_Numero_futuro (a.spriden_pidm) Numero_Cargos_Proximos,
                                to_date (PKG_REPORTES_1.f_fechacorte (a.spriden_pidm), 'dd/mm/rrrr') Prox_Fecha_Limite_Pag,
                                to_date (PKG_REPORTES_1.f_fechacorte (a.spriden_pidm),'dd/mm/rrrr' )  - trunc (sysdate) Num_Dias_Prox_Pago,
                                PKG_REPORTES_1.f_pago_total (a.spriden_pidm)  Suma_depositos,
                                PKG_REPORTES_1.f_num_total_pago (a.spriden_pidm)  Numero_Depositos,
                                (PKG_REPORTES_1.f_saldodia (a.spriden_pidm) * h.Incobrable) Monto_Incobrable,
                                case
                                when h.Incobrable = .0 then
                                         '0%'
                                when h.Incobrable = .5 then
                                         '5%'
                                when h.Incobrable = .10 then
                                         '10%'
                                when h.Incobrable = .20 then
                                         '20%'
                                when h.Incobrable = .30 then
                                         '30%'
                                when h.Incobrable = .60 then
                                         '60%'
                                when h.Incobrable = .85 then
                                         '85%'
                            End as Provision_Incobrable,
                                null Ultimo_Acceso_Plataforma,
                                null Rango_dias_acceso_plataforma,
                                PKG_REPORTES_1.f_jornada (a.spriden_pidm)   Jornada_Plan,
                                PKG_REPORTES_1.f_no_materia (a.spriden_pidm) Carga_Academica,
                                pkg_datos_academicos.acreditadas1(a.spriden_pidm ,f.programa ) Materias_Aprobadas,
                                pkg_datos_academicos.avance1(a.spriden_pidm ,f.programa ) Avance_Curricular,
                                pkg_datos_academicos.promedio1(a.spriden_pidm ,f.programa ) Promedio,
                                to_date (PKG_REPORTES_1.f_fecha_Matriculacion (a.spriden_pidm), 'dd/mm/rrrr') Fecha_Matriculacion,
                                PKG_REPORTES_1.f_periodo_inicial (a.spriden_pidm) Ciclo_Inicial,
                                PKG_REPORTES_1.f_Estado_programa (a.spriden_pidm) Estado_alumno_programa,
                                f.programa Programa_Code,
                                f.Nombre_Programa Nombre_Programa,
                               nvl (PKG_REPORTES_1.f_Descuento (a.spriden_pidm), 0) Descuento,
                               g.referencia Referencia_Bancaria
            from spriden a, correo_principal b, correo_alterno c, telefono_casa d, telefono_celular e, curricula f, Referencia g, Incobrable h
            Where A.SPRIDEN_CHANGE_IND is null
                And a.spriden_pidm = b.Pidm (+)
                And a.spriden_pidm = c.Pidm (+)
                And a.spriden_pidm = d.Pidm (+)
                And a.spriden_pidm = e.Pidm (+)
                And a.spriden_pidm = f.Pidm (+)
                And a.spriden_pidm = g.Pidm (+)
                And a.spriden_pidm = h.Pidm (+)
order by 1

            )loop

                Insert into TZTCRTE values (acafin.usuario_id,
                                                        acafin.Matricula,
                                                        acafin.Campus,
                                                        acafin.Nivel_Code,
                                                        acafin.Nivel_Academico,
                                                        acafin.Nombre,
                                                        acafin.Correo_Principal,
                                                        acafin.Correo_Alterno,
                                                        acafin.Telefono_Casa,
                                                        acafin.Telefono_Celular,
                                                        acafin.Saldo_Total,
                                                        acafin.Saldo_Vencido,
                                                        acafin.Numero_Cargo_Vencido,
                                                        acafin.Primer_fecha_limite_de_pago,
                                                        acafin.Ultima_fecha_limite_de_pago,
                                                        acafin.Dias_Atraso,
                                                        acafin.Meses_Atraso,
                                                        acafin.Mora,
                                                        acafin.Total_montos_Prox,
                                                        acafin.Saldo_Prox,
                                                        acafin.Numero_Cargos_Proximos,
                                                        acafin.Prox_Fecha_Limite_Pag,
                                                        acafin.Num_Dias_Prox_Pago,
                                                        acafin.Suma_depositos,
                                                        acafin.Numero_Depositos,
                                                        acafin.Monto_Incobrable,
                                                        acafin.Provision_Incobrable,
                                                        acafin.Ultimo_Acceso_Plataforma,
                                                        acafin.Rango_dias_acceso_plataforma,
                                                        acafin.Jornada_Plan,
                                                        acafin.Carga_Academica,
                                                        acafin.Materias_Aprobadas,
                                                        acafin.Avance_Curricular,
                                                        acafin.Promedio,
                                                        acafin.Fecha_Matriculacion,
                                                        acafin.Ciclo_Inicial,
                                                        acafin.Estado_alumno_programa,
                                                        acafin.Programa_Code,
                                                        acafin.Nombre_Programa,
                                                        acafin.Descuento,
                                                        acafin.Referencia_Bancaria,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        'Academico_Financiero'
                                                        );

            End loop;
            commit;
        End;
    END;


Procedure sp_Hist_Acad_Compac

is

    BEGIN

        Begin

            delete TZTCRTE
                where TZTCRTE_TIPO_REPORTE = 'Historial_Academico_Compactado';
                Commit;

            for c in (

            select x.pidm, x.nombre, x.Matricula, x.Programa, x.Nombre_Programa, x.Estatus, x.Aprobadas, x.Reprobadas, x.En_Curso, x.Por_Cursar, x.Total,  to_number (x.avance) avance
            from (
                       select  distinct spriden_pidm pidm,
                            replace(SPRIDEN_LAST_NAME,'/',' ') || ' ' || SPRIDEN_FIRST_NAME as Nombre,
                            SPRIDEN_ID as Matricula,
                            SORLCUR_PROGRAM as Programa,
                            SZTDTEC_PROGRAMA_COMP Nombre_Programa,
                            STVSTST_DESC Estatus,
                            (select to_char(pkg_datos_academicos.acreditadas1(spriden_pidm, sorlcur_program)) from dual) Aprobadas,
                            (select to_char(pkg_datos_academicos.reprobadas(spriden_pidm, sorlcur_program)) from dual) Reprobadas,
                            (select to_char(pkg_datos_academicos.e_cur(spriden_pidm, sorlcur_program)) from dual) En_Curso,
                            ((select to_number(pkg_datos_academicos.total_mate(sorlcur_program, spriden_pidm)) from dual) -
                            (select to_number(pkg_datos_academicos.acreditadas1(spriden_pidm, sorlcur_program)) from dual) -
                            (select to_char(pkg_datos_academicos.e_cur(spriden_pidm, sorlcur_program)) from dual))Por_Cursar,
                            (select to_char(pkg_datos_academicos.total_mate(sorlcur_program, spriden_pidm)) from dual) Total,
                            CASE WHEN (select pkg_datos_academicos.avance1(spriden_pidm, sorlcur_program) from dual) > 100
                            THEN 100 ELSE (select pkg_datos_academicos.avance1(spriden_pidm, sorlcur_program) from dual) END avance
                        from SPRIDEN
                        join SORLCUR s on SPRIDEN_PIDM = SORLCUR_PIDM AND SORLCUR_LMOD_CODE='LEARNER' AND SORLCUR_seqno in (select max(sorlcur_seqno) from sorlcur ss
                                                                 WHERE s.sorlcur_pidm=ss.sorlcur_pidm and s.sorlcur_lmod_code=ss.sorlcur_lmod_code and s.sorlcur_program=ss.sorlcur_program)
                        join sgbstdn sg on sgbstdn_pidm=sorlcur_pidm and sg.sgbstdn_program_1 = s.sorlcur_program and sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn sgb
                                                                 WHERE sg.sgbstdn_pidm=sgb.sgbstdn_pidm and sorlcur_levl_code=sgbstdn_levl_code
                                                                 AND sg.sgbstdn_program_1 = sgb.sgbstdn_program_1)
                        join stvstst on stvstst_code=sgbstdn_stst_code
                        join sztdtec on sztdtec_program=sorlcur_program
                        where SPRIDEN_CHANGE_IND is null
                        order by Programa,matricula
                        ) x

            ) loop

               Insert into TZTCRTE values (c.pidm,
                                                       c.Matricula,
                                                       null,
                                                       null,
                                                       c.Nombre,
                                                       c.Programa,
                                                       c.Nombre_Programa,
                                                       c.Estatus,
                                                       c.Aprobadas,
                                                       c.Reprobadas,
                                                       c.En_Curso,
                                                       c.Por_Cursar,
                                                       c.Total,
                                                        c.avance,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        'Historial_Academico_Compactado'
                                                        );

            End loop;
            commit;
        End;
    END;

FUNCTION   p_fecha_max (p_pidm in number) Return varchar2
is
--vl_fecha_ini date;
vl_salida varchar2(250):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



        select   max (x.fecha_inicio) --, rownum
            into   vl_fecha
        from (
        SELECT DISTINCT
                   MAX (SSBSECT_PTRM_END_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
                FROM SFRSTCR a, SSBSECT b
               WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                     AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                     AND a.SFRSTCR_RSTS_CODE = 'RE'
                     AND b.SSBSECT_PTRM_END_DATE =
                            (SELECT MAX (b1.SSBSECT_PTRM_END_DATE)
                               FROM SSBSECT b1
                              WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                    AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
               and  SFRSTCR_pidm = p_pidm
            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
            order by 1,3 asc
            )  x
            order by 1 asc;






    Exception
    When Others then
      vl_fecha := '01/01/1900';
    End;

        return vl_fecha;

Exception
When Others then
  vl_fecha := '01/01/1900';
 return vl_fecha;
END p_fecha_max;


Procedure sp_pagos_facturacion_dia is

Begin

        Begin
            delete TZTCRTE
            where TZTCRTE_TIPO_REPORTE in ( 'Pago_Facturacion_dia', 'Facturacion_dia');
            Commit;
        Exception
        When others then
           null;
        End;


        Begin
                For c in (

        with colegiatura as (
                        Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbraccd_desc desc_cargo, TBBDETC_DCAT_CODE Categ_Col
                        from tbraccd a, tbbdetc b
                        where a.tbraccd_detail_code = tbbdetc_detail_code
                        ),
                curp as (select GORADID_PIDM PIDM,
                        GORADID_ADDITIONAL_ID CURP
                     from GORADID
                     where GORADID_ADID_CODE = 'CURP')
                        select DISTINCT
                           tbraccd_pidm pidm ,
                          spriden_id as Matricula,
                          SPREMRG_LAST_NAME as Nombre,
                          saradap_camp_code as Campus,
                          SARADAP_LEVL_CODE as Nivel,
                          SPREMRG_MI as RFC,
                          SPREMRG_STREET_LINE1 || ' ' ||SPREMRG_STREET_LINE2 || ' ' || SPREMRG_STREET_LINE3 as Dom_Fiscal,
                          SPREMRG_CITY as Ciudad,
                          SPREMRG_ZIP as CP,
                          SPREMRG_NATN_CODE as Pais,
                          tbraccd_detail_code as Tipo_Deposito,
                          tbraccd_desc as Descripcion,
                          tbraccd_amount as Monto,
                          TBRACCD_TRAN_NUMBER as Transaccion,
                          TO_CHAR(TBRACCD_TRANS_DATE, 'YYYY-MM-DD"T"HH24:MI:SS') fecha_pago,
                          GORADID_ADDITIONAL_ID as REFERENCIA,
                          GORADID_ADID_CODE as Referencia_Tipo,
                          GOREMAL_EMAIL_ADDRESS as EMAIL,
                          TBRAPPL_AMOUNT as Monto_pagado,
                          TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                          colegiatura.desc_cargo descripcion_pago,
                          colegiatura.Categ_Col,
                          min(SPREMRG_PRIORITY) Prioridad,
                          curp.CURP,
                          SARADAP_DEGC_CODE_1 Grado,
                          SPREMRG_LAST_NAME Razon_social,
                          SARADAP_PROGRAM_1 programa
                        from SPREMRG
                        left join SPRIDEN on SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
                        left join TBRACCD on SPREMRG_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE) = trunc (sysdate)
                        left join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                        left join SARADAP on SPREMRG_PIDM = SARADAP_PIDM
                        left join GORADID on SPREMRG_PIDM = GORADID_PIDM and GORADID_ADID_CODE in ('REFH','REFS')
                        left join GOREMAL on SPREMRG_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                        left outer join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                        left outer join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                        left outer join curp on SPRIDEN_PIDM = curp.PIDM
                        where
                          SPREMRG_MI is not NULL
                          and TBBDETC_TYPE_IND = 'P'
                          and TBBDETC_DCAT_CODE = 'CSH'
                          and SPREMRG_PRIORITY in (select MIN(s1.SPREMRG_PRIORITY)
                                                                   FROM SPREMRG s1
                                                                    where SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                                        and SPREMRG_PRIORITY = s1.SPREMRG_PRIORITY)
                        GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, saradap_camp_code, SARADAP_LEVL_CODE, SPREMRG_MI,
                                        SPREMRG_STREET_LINE1 || ' ' ||SPREMRG_STREET_LINE2 || ' ' || SPREMRG_STREET_LINE3, SPREMRG_CITY, SPREMRG_ZIP, SPREMRG_NATN_CODE,
                                        tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, TO_CHAR(TBRACCD_TRANS_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'),  GORADID_ADDITIONAL_ID,
                                        GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                        curp.CURP, SARADAP_DEGC_CODE_1, SARADAP_PROGRAM_1
                        union
                        select DISTINCT
                           tbraccd_pidm pidm ,
                          spriden_id as Matricula,
                          null as Nombre,
                          saradap_camp_code as Campus,
                          SARADAP_LEVL_CODE as Nivel,
                          null as RFC,
                        null as Dom_Fiscal,
                        null as Ciudad,
                        null as CP,
                        null as Pais,
                          tbraccd_detail_code as Tipo_Deposito,
                          tbraccd_desc as Descripcion,
                          tbraccd_amount as Monto,
                          TBRACCD_TRAN_NUMBER as Transaccion,
                         TO_CHAR(TBRACCD_TRANS_DATE, 'YYYY-MM-DD"T"HH24:MI:SS') fecha_pago,
                          GORADID_ADDITIONAL_ID as REFERENCIA,
                          GORADID_ADID_CODE as Referencia_Tipo,
                          GOREMAL_EMAIL_ADDRESS as EMAIL,
                          TBRAPPL_AMOUNT as Monto_pagado,
                          TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
                          colegiatura.desc_cargo descripcion_pago,
                          NVL(colegiatura.Categ_Col, 'COL')Categ_Col,
                          null Prioridad,
                          curp.CURP,
                          SARADAP_DEGC_CODE_1 Grado,
                         null Razon_social,
                         SARADAP_PROGRAM_1 programa
                        from SPRIDEN
                        left join TBRACCD on SPRIDEN_PIDM = TBRACCD_PIDM and trunc (TBRACCD_ENTRY_DATE) = trunc (sysdate)
                        left join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                        left join SARADAP on SPRIDEN_PIDM = SARADAP_PIDM
                        left join GORADID on SPRIDEN_PIDM = GORADID_PIDM and GORADID_ADID_CODE in ('REFH','REFS')
                        left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                        left outer join tbrappl on spriden_pidm = tbrappl_pidm and  TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
                        left outer join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
                        left outer join curp on SPRIDEN_PIDM = curp.PIDM
                        where 1= 1
                          and TBBDETC_TYPE_IND = 'P'
                          and TBBDETC_DCAT_CODE = 'CSH'
                          And spriden_pidm not in (select SPREMRG_pidm from SPREMRG)
                        GROUP BY tbraccd_pidm, spriden_id,
                                        saradap_camp_code, SARADAP_LEVL_CODE,
                                        tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER,TO_CHAR(TBRACCD_TRANS_DATE, 'YYYY-MM-DD"T"HH24:MI:SS'), GORADID_ADDITIONAL_ID,
                                        GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
                                        curp.CURP, SARADAP_DEGC_CODE_1,SARADAP_PROGRAM_1
                      ) loop

                      Insert into TZTCRTE values (c.pidm,
                                                               c.matricula,
                                                                c.campus,
                                                                c.nivel,
                                                                c.nombre,
                                                                c.rfc,
                                                                c.dom_fiscal,
                                                                c.ciudad,
                                                                c.cp,
                                                                c.pais,
                                                                c.tipo_deposito,
                                                                c.descripcion,
                                                                c.monto,
                                                                c.transaccion,
                                                                c.fecha_pago,
                                                                c.referencia,
                                                                c.referencia_tipo,
                                                                c.email,
                                                                c.monto_pagado,
                                                                c.secuencia_pago,
                                                                c.descripcion_pago,
                                                                c.Categ_Col,
                                                                c.Prioridad,
                                                                c.CURP,
                                                                c.Grado,
                                                                c.Razon_social,
                                                                null,
                                                                null,
                                                                null,
                                                                null,--c.programa,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,--USER||' - sp_pagos_facturacion_dia',
                                                                null,-- '27/09/2019', --TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'),
                                                                null,
                                                                'Pago_Facturacion_dia'
                                                                );




                End Loop;
        Commit;

             For c in (with intereses as (select distinct
                                    TZTCRTE_PIDM Pidm,
                                    TZTCRTE_LEVL as Nivel,
                                    TZTCRTE_CAMP as Campus,
                                    TZTCRTE_CAMPO11  as Fecha_Pago,
                                    TZTCRTE_CAMPO17 as Intereses,
                                    sum (TZTCRTE_CAMPO15) as Monto_intereses,
                                    TZTCRTE_CAMPO18 as Categoria,
                                    TZTCRTE_CAMPO10 as Secuencia,
                                    TZTCRTE_CAMPO26 programa
                                    from TZTCRTE
                                    where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                    and TZTCRTE_CAMPO18 = 'INT'
                                    group by
                                              TZTCRTE_PIDM,
                                              TZTCRTE_LEVL,
                                              TZTCRTE_CAMP,
                                              TZTCRTE_CAMPO11,
                                              TZTCRTE_CAMPO17,
                                              TZTCRTE_CAMPO18,
                                              TZTCRTE_CAMPO10,
                                              TZTCRTE_CAMPO26
                                    ),
                                    accesorios as (
                                    select distinct
                                              TZTCRTE_PIDM Pidm,
                                              TZTCRTE_LEVL as Nivel,
                                              TZTCRTE_CAMP as Campus,
                                              TZTCRTE_CAMPO11  as Fecha_Pago,
                                              TZTCRTE_CAMPO17 as accesorios,
                                              sum (TZTCRTE_CAMPO15) as Monto_accesorios,
                                              TZTCRTE_CAMPO18 as Categoria,
                                              TZTCRTE_CAMPO10 as Secuencia,
                                              TZTCRTE_CAMPO26 programa
                                    from TZTCRTE
                                    where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                    and TZTCRTE_CAMPO18 in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                                    group by
                                              TZTCRTE_PIDM,
                                              TZTCRTE_LEVL,
                                              TZTCRTE_CAMP,
                                              TZTCRTE_CAMPO11,
                                              TZTCRTE_CAMPO17,
                                              TZTCRTE_CAMPO18,
                                              TZTCRTE_CAMPO10,
                                              TZTCRTE_CAMPO26
                                    ),
                                    colegiatura as (
                                    select distinct
                                              TZTCRTE_PIDM Pidm,
                                              TZTCRTE_LEVL as Nivel,
                                              TZTCRTE_CAMP as Campus,
                                              TZTCRTE_CAMPO11  as Fecha_Pago,
                                              TZTCRTE_CAMPO17 as colegiatura,
                                              sum (TZTCRTE_CAMPO15) as Monto_colegiatura,
                                              TZTCRTE_CAMPO18 as Categoria,
                                              TZTCRTE_CAMPO10 as Secuencia,
                                              TZTCRTE_CAMPO26 programa
                                    from TZTCRTE
                                    where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                    and TZTCRTE_CAMPO18 in  ('COL')
                                    group by
                                              TZTCRTE_PIDM,
                                              TZTCRTE_LEVL,
                                              TZTCRTE_CAMP,
                                              TZTCRTE_CAMPO11,
                                              TZTCRTE_CAMPO17,
                                              TZTCRTE_CAMPO18,
                                              TZTCRTE_CAMPO10,
                                              TZTCRTE_CAMPO26
                                    ),
                                    otros as (
                                    select distinct
                                              TZTCRTE_PIDM Pidm,
                                              TZTCRTE_LEVL as Nivel,
                                              TZTCRTE_CAMP as Campus,
                                              TZTCRTE_CAMPO11  as Fecha_Pago,
                                              TZTCRTE_CAMPO17 as otros,
                                              sum (TZTCRTE_CAMPO15) as Monto_otros,
                                              TZTCRTE_CAMPO18 as Categoria,
                                              TZTCRTE_CAMPO10 as Secuencia,
                                              TZTCRTE_CAMPO26 programa
                                    from TZTCRTE
                                    where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                    and TZTCRTE_CAMPO18 not in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL', 'VTA', 'TUI')
                                    group by
                                              TZTCRTE_PIDM,
                                              TZTCRTE_LEVL,
                                              TZTCRTE_CAMP,
                                              TZTCRTE_CAMPO11,
                                              TZTCRTE_CAMPO17,
                                              TZTCRTE_CAMPO18,
                                              TZTCRTE_CAMPO10,
                                              TZTCRTE_CAMPO26
                                    )
                                    select distinct
                                              TZTCRTE_pidm as pidm,
                                              TZTCRTE_CAMPO1 as Nombre,
                                              TZTCRTE_CAMPO2 as RFC,
                                              TZTCRTE_CAMPO3 as Dom_Fiscal,
                                              TZTCRTE_CAMPO4 as Ciudad,
                                              TZTCRTE_CAMPO5 as CP,
                                              TZTCRTE_CAMPO6 as Pais,
                                              TZTCRTE_CAMPO7 as Tipo_Deposito,
                                              TZTCRTE_CAMPO8 as Descripcion,
                                              TZTCRTE_CAMPO9 as Monto,
                                              TZTCRTE_LEVL as Nivel,
                                              TZTCRTE_CAMP as Campus,
                                              TZTCRTE_ID as Matricula,
                                              TZTCRTE_CAMPO10  as Transaccion,
                                              TZTCRTE_CAMPO11  as Fecha_Pago,
                                              TZTCRTE_CAMPO12 as REFERENCIA,
                                              TZTCRTE_CAMPO13 as Referencia_Tipo,
                                              TZTCRTE_CAMPO14  as EMAIL,
                                              e.Colegiatura,
                                              e.Monto_colegiatura,
                                              b.intereses,
                                              b.Monto_intereses,
                                              c.accesorios,
                                              c.Monto_accesorios,
                                              d.otros,
                                              d.monto_otros,
                                              TZTCRTE_CAMPO20 as Curp,
                                              TZTCRTE_CAMPO21 as Grado,
                                              TZTCRTE_CAMPO22 as Razon_social,
                                              TZTCRTE_CAMPO26 programa
                                    from TZTCRTE, intereses b, accesorios c, otros d, colegiatura e
                                    where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
                                         --and TZTCRTE_CAMP = :MC_CAMPUS
                                         --and TZTCRTE_LEVL = :MC_NIVEL
                                    --and to_date(TZTCRTE_CAMPO11,'dd/mm/rrrr') BETWEEN to_date(:Fecha_Inicio, 'dd/mm/rrrr') and to_date(:Fecha_Fin, 'dd/mm/rrrr')
                                    --And TZTCRTE_ID = '010041922'
                                    and TZTCRTE_CAMPO18 in ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL')
                                   --and TZTCRTE_CAMPO18 = 'COL' (+)
                                  and TZTCRTE_PIDM = e.pidm (+)
                                    and TZTCRTE_LEVL = e.nivel (+)
                                    and TZTCRTE_CAMP = e.campus (+)
                                    and TZTCRTE_CAMPO11 = e.Fecha_Pago (+)
                                    And TZTCRTE_CAMPO10 = e.secuencia (+)
                                    and TZTCRTE_PIDM = b.pidm (+)
                                    and TZTCRTE_LEVL = b.nivel (+)
                                    and TZTCRTE_CAMP = b.campus (+)
                                    and TZTCRTE_CAMPO11 = b.Fecha_Pago (+)
                                    And TZTCRTE_CAMPO10 = b.secuencia (+)
                                    and TZTCRTE_PIDM = c.pidm (+)
                                    and TZTCRTE_LEVL = c.nivel (+)
                                    and TZTCRTE_CAMP = c.campus (+)
                                    and TZTCRTE_CAMPO11 = c.Fecha_Pago (+)
                                    And TZTCRTE_CAMPO10 = c.secuencia (+)
                                    and TZTCRTE_PIDM = d.pidm (+)
                                    and TZTCRTE_LEVL = d.nivel (+)
                                    and TZTCRTE_CAMP = d.campus (+)
                                    and TZTCRTE_CAMPO11 = d.Fecha_Pago (+)
                                    And TZTCRTE_CAMPO10 = d.secuencia (+)
                                    --and TZTCRTE_PIDM = f.SPRIDEN_PIDM
                                    group by TZTCRTE_pidm,
                                              TZTCRTE_CAMPO1,
                                              TZTCRTE_CAMPO2,
                                              TZTCRTE_CAMPO3,
                                              TZTCRTE_CAMPO4,
                                              TZTCRTE_CAMPO5,
                                              TZTCRTE_CAMPO6,
                                              TZTCRTE_CAMPO7,
                                              TZTCRTE_CAMPO8,
                                              TZTCRTE_CAMPO9,
                                              TZTCRTE_LEVL,
                                              TZTCRTE_CAMP,
                                              TZTCRTE_ID,
                                              TZTCRTE_CAMPO10,
                                              TZTCRTE_CAMPO11,
                                              TZTCRTE_CAMPO12,
                                              TZTCRTE_CAMPO13,
                                              TZTCRTE_CAMPO14,
                                              e.Colegiatura,
                                              e.Monto_colegiatura,
                                              b.intereses,
                                              b.Monto_intereses,
                                              c.accesorios,
                                              c.Monto_accesorios,
                                              d.otros,
                                              d.monto_otros,
                                              TZTCRTE_CAMPO20,
                                              TZTCRTE_CAMPO21,
                                              TZTCRTE_CAMPO22
                                             order by TZTCRTE_ID, TZTCRTE_CAMPO11, TZTCRTE_CAMPO10 ) loop

                              Insert into TZTCRTE values (c.pidm,
                                                               c.matricula,--
                                                                c.campus,--
                                                                c.nivel,--
                                                                c.nombre,--
                                                                c.rfc,--
                                                                c.dom_fiscal,--
                                                                c.ciudad, --
                                                                c.cp, --
                                                                c.pais,--
                                                                c.tipo_deposito,--
                                                                c.descripcion,--
                                                                c.monto,--
                                                                c.transaccion,--
                                                                c.fecha_pago,--
                                                                c.referencia,--
                                                                c.referencia_tipo,--
                                                                c.email,--
                                                                c.colegiatura,
                                                                c.monto_colegiatura,
                                                                c.intereses,
                                                                c.monto_intereses,
                                                                c.accesorios,
                                                                c.monto_accesorios,
                                                                c.otros,
                                                                c.monto_otros,
                                                                c.CURP,
                                                                c.Grado,
                                                                c.Razon_social,
                                                                null,--c.programa,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null,
                                                                null, --USER||' - sp_pagos_facturacion_dia',
                                                                null,--'27/09/2019', --TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'),
                                                                'Facturacion_dia'
                                                                );

            End loop;


        End;

End sp_pagos_facturacion_dia;



procedure sp_materias_reprobadas as

Begin


        EXECUTE IMMEDIATE 'TRUNCATE TABLE migra.reprobadas';
        commit;


    For cx in (

                Select distinct matricula, campus, nivel, sp, estatus
                from tztprog
                where 1=1
                and estatus not in ('CC','CP', 'CV')

             ) loop


                For cx2 in (


                            Select distinct a.matricula,
                            spriden_last_name||spriden_first_name NOMBRE,
                            a.estatus,
                            a.campus,
                            a.nivel,
                            a.nombre programa,
                            get_materia_padre(d.ssbsect_subj_code ||d.ssbsect_crse_numb) materia_padre,
                            d.ssbsect_subj_code || d.ssbsect_crse_numb  materia_hija,
                            c.sfrstcr_crn Grupo,
                            c.SFRSTCR_GRDE_CODE Calificacion,
                            SCBCRSE_TITLE nombre_materia,
                            c.sfrstcr_rsts_code estatus_mat,
                            pkg_utilerias.f_correo(a.pidm,'PRIN')Correo,
                            pkg_utilerias.f_correo(a.pidm,'ALTE')CorreoAlternativo,
                            pkg_utilerias.f_celular(a.pidm,'RESI') Telefono,
                            pkg_utilerias.f_celular(a.pidm,'CELU') Celular
                            from tztprog a
                            join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
                            join sfrstcr c on sfrstcr_pidm = a.pidm and c.SFRSTCR_STSP_KEY_SEQUENCE = a.sp
                            join ssbsect d on d.ssbsect_term_code = c.sfrstcr_term_code
                                        and d.ssbsect_ptrm_code = c.sfrstcr_ptrm_code
                                        and d.ssbsect_crn = c.sfrstcr_crn
                            join shrgrde on SHRGRDE_CODE = c.SFRSTCR_GRDE_CODE
                                           and SHRGRDE_PASSED_IND ='N'
                                           and SFRSTCR_LEVL_CODE =SHRGRDE_LEVL_CODE
                            join SCBCRSE on SCBCRSE_SUBJ_CODE|| SCBCRSE_CRSE_NUMB = d.ssbsect_subj_code || d.ssbsect_crse_numb
                            Where 1=1
                            And a.sp = (select max (a1.sp)
                                        from tztprog a1
                                        where 1=1
                                        And a.pidm = a1.pidm
                                        And a.programa = a1.programa)
                          --  And a.estatus not in ('CC','CP', 'CV')
                            And c.SFRSTCR_RSTS_CODE = 'RE'
                            And d.ssbsect_subj_code || d.ssbsect_crse_numb  not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                            and d.ssbsect_subj_code || d.ssbsect_crse_numb not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB')
                            And c.SFRSTCR_GRDE_CODE is not null
                            And a.matricula = cx.matricula
                            And a.campus = cx.campus
                            And a.nivel = cx.nivel
                            And a.estatus = cx.estatus
                            And a.sp = cx.sp

                 ) loop


                        Begin
                                Insert into reprobadas values (cx2.matricula,
                                                               cx2.nombre,
                                                               cx2.estatus,
                                                               cx2.campus,
                                                               cx2.nivel,
                                                               cx2.programa,
                                                               cx2.materia_padre,
                                                               cx2.materia_hija,
                                                               cx2.grupo,
                                                               cx2.calificacion,
                                                               cx2.nombre_materia,
                                                               cx2.estatus_mat,
                                                               cx2.correo,
                                                               cx2.correoalternativo,
                                                               cx2.telefono,
                                                               cx2.celular);
                        Exception
                            When Others then
                                null;
                        End;


                End Loop cx2;
                commit;
    End Loop cx;
    Commit;

End sp_materias_reprobadas;




FUNCTION F_INSERT_BITCT (ppidm number, pfecha_siu date,paccion_siu varchar2, puser_siu varchar2, ptipo_doc varchar2, pprograma varchar2,PUSR_NOMBRE VARCHAR2 )
RETURN VARCHAR2
IS
/*
funcion que se ejecuta desde siu para llenar tabla intermedia con información de los cambios y ajustes que tiene
los certificados y títulos digitales y sirve para hacer el reporte.

autor: glovicx
fecha: 17/08/2023
SZT_PIDM--- pidm del alumno este lo puede sacar con la sig función fget_pidm('matrícula')
SZT_FECHA_CAMBIOS_SIU  -- fecha en que hubo un movimiento
SZT_ACCION_SIU-- que tipo de acción hizo
SZT_USUARIO_SIU--- usuario quien realizo la acción
SZT_TIPO_DOCUMENTO-- tipo C=certificados ; T=títulos
*/

vsalida     varchar2(200):= 'EXITO';
vnivel        varchar2(4);
vcampus    varchar2(4);
vtipo_ingreso  varchar2(4);
vuser_banner varchar2(50);
vfecha_banner varchar2(50);


BEGIN
NULL;
---- borramos el historial solo se queda lo de 3 meses----
begin
      delete
         from SZTBITCT t2
           where 1=1
            and trunc(T2.SZT_ACTIVITY_DATE) <= (trunc(sysdate)-90) ;

exception when others then
null;
end;



  begin --- primero sacamos algunos datos para la tabla
             select distinct ss.SGBSTDN_LEVL_CODE, ss.SGBSTDN_CAMP_CODE, SS.SGBSTDN_ADMT_CODE
                INTO vnivel, vcampus, vtipo_ingreso
                    from SGBSTDN ss, sztrece tt, STVADMT yy
                      where 1=1
                        and ss.SGBSTDN_PIDM = TT.SZTRECE_PIDM_CERTIF
                        and SS.SGBSTDN_PROGRAM_1  = TT.SZTRECE_PROGRAM_CERTIF
                        and SS.SGBSTDN_ADMT_CODE  = yy.STVADMT_CODE
                      --  and ss.SGBSTDN_STST_CODE      =  'EG'
                        and tt.SZTRECE_PROGRAM_CERTIF = pprograma
                        and tt.SZTRECE_PIDM_CERTIF        = ppidm
                            ;

           exception when others then

                          begin
                                 select tt.nivel, tt.campus, TT.TIPO_INGRESO
                                    into vnivel, vcampus, vtipo_ingreso
                                        from tztprog tt
                                        where 1=1
                                        and tt.pidm = ppidm
                                        and tt.programa = pprograma;
                             exception when others then
                             vnivel:=null;
                             vcampus :=null;
                             vtipo_ingreso :=null;
                             end;

          vnivel:=null;
          vcampus :=null;
          vtipo_ingreso :=null;

         end;

        begin  -----sacamos los datos de trece para completar tabla

           select c.SZTRECE_ACTIVITY_DATE fecha_mov, lower(c.SZTRECE_USER) usuario
                INTO  vfecha_banner, vuser_banner
               from sztrece c
                where 1=1
                    and c.SZTRECE_PIDM_CERTIF         = ppidm
                    and c.SZTRECE_PROGRAM_CERTIF  = pprograma;
        exception when others then
          vfecha_banner := null;
          vuser_banner  := null;

        end;


      begin

         insert into SZTBITCT
                      (SZT_PIDM,
                        SZT_CAMPUS,
                        SZT_NIVEL,
                        SZT_PROGRAMA,
                        SZT_TIPO_INGRESO,
                        SZT_FECHA_CAMBIOS_BANNER,
                        SZT_USUARIO_BANNER,
                        SZT_FECHA_CAMBIOS_SIU,
                        SZT_ACCION_SIU,
                        SZT_USUARIO_SIU,
                        SZT_TIPO_DOCUMENTO,
                        SZT_ACTIVITY_DATE,
                        SZT_USER_SIU_NOMBRE
                        )
             values (ppidm, vcampus, vnivel, pprograma, vtipo_ingreso,vfecha_banner, lower(vuser_banner), pfecha_siu,paccion_siu,puser_siu,upper(ptipo_doc), SYSDATE,PUSR_NOMBRE );

      exception when others then
       vsalida := sqlerrm ;

      end;



return (vsalida);

END F_INSERT_BITCT;


END PKG_REPORTES_1;
/

DROP PUBLIC SYNONYM PKG_REPORTES_1;

CREATE OR REPLACE PUBLIC SYNONYM PKG_REPORTES_1 FOR BANINST1.PKG_REPORTES_1;
