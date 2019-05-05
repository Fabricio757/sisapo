create or replace PACKAGE BODY RH_SINCRONIZACION AS

  PROCEDURE Exportacion(pIdServidorOrigen integer, pIdServidorDestino integer, pIdUsuario integer) AS
  
    HayNro                  integer;  
    vUltimoNroLote          integer;
    vNuevoNroLote           integer;
    vStatus                 integer; 
    vAhora                  date;
    vFechaUltimoResultado   date;
  
  BEGIN     
    
    vAhora := sysdate();
    
    select count(1) into HayNro from RH_SINCRONIZACIONES where IdServidorOrigen = pIdServidorOrigen and IdServidorDestino = pIdServidorDestino;
    dbms_output.put_line('Hay Nro: ' || HayNro);
    
    if HayNro > 0 then
    
        select Max(nroLote) into vUltimoNroLote from RH_SINCRONIZACIONES where IdServidorOrigen = pIdServidorOrigen and IdServidorDestino = pIdServidorDestino;
    
        select status, fecha into vStatus, vFechaUltimoResultado from RH_SINCRONIZACIONES 
            where IdServidorOrigen = pIdServidorOrigen and IdServidorDestino = pIdServidorDestino and NROLOTE = vUltimoNroLote;
    
        --La exportación anterior tiene que estar confirmada
        if vStatus > 0 then            
            
            --Genero el proximo Lote Nro de Lote
            vNuevoNroLote := vUltimoNroLote + 1;            
            insert into RH_SINCRONIZACIONES 
            (IDSERVIDORORIGEN, IDSERVIDORDESTINO, EXPORTACION, IMPORTACION, NROLOTE, FECHA, IDUSUARIO, FECHARESULTADO, STATUS)
            values 
            (pIdServidorOrigen, pIdServidorDestino, NULL, NULL, vNuevoNroLote, sysdate, pIdUsuario, null, 0);
            
            
            --Cargo las altas nuevas
            insert into RH_PERSONAL_LOG_LT
            --(vNuevoNroLote, STATUS, ID, IDPERSONAL, APELLIDO, NOMBRE, DNI, FECHA_NAC, SEXO, CUIL, SINDICAL, IDCATEGORIA, IDESPECIALIDAD, IDFASE, LEGAJO, IDUSUARIOALTA, FECHAALTA, IDUSUARIOULTMODIF, FECHAULTMODIF, IDTURNO, IDOBRA, IDPS, IDTIPOEMPLEADO, FORANEO, SUBCONTRATADO, IDFUNCION, TURNODIURNONOCTURNO, IDSUBCONTRATISTA, OPERACION, FECHA, IDUSUARIO, SALDODIASFRANCO, SALDODIASVACACIONES, IDORIGEN, IDCIUDAD, DOMICILIO, IDPROVINCIA, MAIL, TELEFONO1, TELEFONO2, RECOMENDADO, IDREGIMEN_FRANCO, IDTIPO_DOCUMENTO, IDNACIONALIDAD, IDTIPO_TRANSPORTE, IDGERENCIA, IDFASETRABAJA, CALLE, NUMERO, PISO, DEPARTAMENTO, CODIGOPOSTAL, EVALUACIONRH, DESCRIPCIONEVRH, IDEVALUADORRH, EVALUACIONLD, DESCRIPCIONEVLD, IDEVALUADORLD)
            select vNuevoNroLote, 0, T.* FROM RH_PERSONAL_LOG T
            WHERE OPERACION = 'ALTA' and Fecha > vFechaUltimoResultado;
            
            --en Intancias
            insert into RH_INSTANCIA_LOG_LT
            select vNuevoNroLote, 0, T.* FROM RH_INSTANCIA_LOG T
            WHERE OPERACION = 'ALTA' and Fecha > vFechaUltimoResultado;
        
            --Cargo las modificaciones nuevas
            insert into RH_PERSONAL_LOG_LT
            SELECT vNuevoNroLote, 0, T.* FROM RH_PERSONAL_LOG T WHERE ID in 
                (SELECT max(ID) FROM RH_PERSONAL_LOG 
                    WHERE OPERACION <> 'ALTA' AND FECHA > vFechaUltimoResultado group by IDPERSONAL);
                    
            --en Intancias
            insert into RH_INSTANCIA_LOG_LT
            SELECT vNuevoNroLote, 0, T.* FROM RH_INSTANCIA_LOG T WHERE ID in 
                (SELECT max(ID) FROM RH_INSTANCIA_LOG 
                    WHERE OPERACION <> 'ALTA' AND FECHA > vFechaUltimoResultado
                    group by IDINSTANCIA);
                    
            --Cargo las Confirmaciones de las importaciones que le tengo que pasar al Destino
            INSERT INTO RH_SINC_CONFIRMACION (IDSERVIDORORIGEN, IDSERVIDORDESTINO, NROLOTE, FECHARESULTADO)
            
            select IDSERVIDORORIGEN, IDSERVIDORDESTINO, NROLOTE, FECHARESULTADO from RH_SINCRONIZACIONES where 
                fechaResultado > vFechaUltimoResultado
                and IdServidorOrigen = pIdServidorDestino and IdServidorDestino = pIdServidorOrigen; --Van cruzados, porque son importaciones
             
        end if;
    
    end if;
    
    NULL;
  END Exportacion;

 PROCEDURE Importacion(pIdServidorOrigen integer, pIdServidorDestino integer, pNroLote integer, pIdUsuario integer) as
 
    HayNro      integer;  
    vUltimoNro  integer;
    vStatus     integer; 
    vAhora      date;
    vFechaFin   date;
    vIdLote     integer;
 
 begin
 
     vAhora := sysdate();
    
    /*select count(nro) into HayNro from RH_SINCRONIZACIONES where IdServidorOrigen = pIdServidorOrigen;
    dbms_output.put_line('Hay Nro: ' || HayNro);
    
    if HayNro > 0 then
    
        for R in (select * from RH_PERSONAL_LOG_LT) loop
        begin
            if R.IdFuncion = 1 then
                insert into RH_PERSONAL values R;
                
            end if;
        end;
    
    end if;*/
 
 end;

END RH_SINCRONIZACION;