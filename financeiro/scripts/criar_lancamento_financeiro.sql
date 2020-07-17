Create or replace procedure "Criar_lancamento_financeiro" (
        p_conta_financeira_id       IN  number,
        p_data                      IN  date,
        p_documento                 IN  varchar2,
        p_valor                     IN  number,
        p_centro_custos_id          IN  number,
        p_categoria_financeira_id   IN  number,
        p_contas_pagas_id           IN  number,
        p_contas_recebidas_id       IN  number,
        p_tipo                      IN  varchar2
    )
IS
    l_tipo_lancamento_id    Number;
    l_record    lancamentos_financeiros%rowtype;
    
Begin
    Select id into l_tipo_lancamento_id
    from tipos_lancamentos_financeiros
    where descricao = 'Financeiro';

    if p_tipo = 'Pagar' then
        l_record.valor_saida := p_valor;
        l_record.valor_entrada := 0;
        l_record.historico := 'Pago conforme documento ' || p_documento;
    else
        l_record.valor_saida := 0;
        l_record.valor_entrada := p_valor;
        l_record.historico := 'Recebido conforme documento ' || p_documento;
    end if;        

    l_record.conta_financeira_id            := p_conta_financeira_id;
    l_record.data                           := p_data;
    l_record.documento                      := p_documento;
    l_record.tipo_lancamento_financeiro_id  := l_tipo_lancamento_id;
    l_record.conciliado                     := 'Não';
    l_record.centro_custo_id                := p_centro_custos_id;
    l_record.categoria_financeira_id        := p_categoria_financeira_id;
    l_record.conta_paga_id                  := p_contas_pagas_id;
    l_record.conta_recebida_id              := p_contas_recebidas_id;

    insert into lancamentos_financeiros values l_record;

End;