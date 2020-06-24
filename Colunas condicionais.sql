select ID,
       CLIENTEID,
       case
           when codigo_bauner is not null then
               codigo_bauner
           else
               null
       end codigo_bauner,
       VENDEDORID,
       CENTROCUSTOSID,
       CATEGORIACUSTOSID,
       DOCUMENTO,
       DATAEMISSAO,
       DATACOMPETENCIA,
       DATAVENCIMENTO,
       VALOR,
       SALDO,
       COMISSAOBASE,
       COMISSAOPERCENTUAL,
       COMISSAOVALOR,
       STATUSID,
       OBSERVACOES,
       case
         when nfid > 0 then
           ''
         else
           'Emitir Nota'
       end nota_link,
       case
         when nfid > 0 then
           ''
         else
           'class="fa fa-list-alt fam-arrow-up fam-is-success" style="color: black;"  title="Emitir Nota Fiscal"'
         end nota_icon,  
       case
         when saldo > 0 then
           'Receber'
         else
           ''
       end receber_link,
       case
         when saldo > 0 then
           'class="fa fa-money terminal fam-arrow-down fam-is-success" style="color: black;"  title="Receber"'
         else
           ''
       end receber_icon,
       'Rateio' rateio_link,
       case
         when saldo = valor then
             'Cancelar'
         else
             ''
       end cancelar_link,
       case
         when saldo = valor then
             'class="fa fa-ban" style="color: red;" title="Cancelar Título"'
         else
             ''
       end cancelar_icon
from CONTASRECEBER
where tenantid = V('SES_TENANTID')  
  

