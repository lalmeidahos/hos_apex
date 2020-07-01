    -- Criar coleção para servir de source para o interactive report
  apex_collection.create_or_truncate_collection('RESUMO_APAGAR');


    -- Adicionar linhas e colunas a coleção
  apex_collection.add_member(
    p_collection_name => 'RESUMO_APAGAR',
    p_c001 =>            'Vencidas ',
    p_n002 =>            apg_vencidas
  );

  apex_collection.add_member(
    p_collection_name => 'RESUMO_APAGAR',
    p_c001 =>            'A Vencer ',
    p_n002 =>            apg_avencer
  );

  apex_collection.add_member(
    p_collection_name => 'RESUMO_APAGAR',
    p_c001 =>            'Cheques Vencidos ',
    p_n002 =>            cheques_vencidos
  );

  apex_collection.add_member(
    p_collection_name => 'RESUMO_APAGAR',
    p_c001 =>            'Cheques a Vencer ',
    p_n002 =>            cheques_avencer
  );

  apex_collection.add_member(
    p_collection_name => 'RESUMO_APAGAR',
    p_c001 =>            'Total ',
    p_n002 =>            apg_total
  );




-->> Exemplo se select na collection:

select
    c001,
    n002,
    case
        when c001 = 'Total ' then
             'bold'
        else
             'normal'
        end as font
  from apex_collections
  where collection_name = 'RESUMO_APAGAR'

