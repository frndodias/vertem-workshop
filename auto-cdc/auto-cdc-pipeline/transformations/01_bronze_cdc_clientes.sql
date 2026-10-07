CREATE OR REFRESH STREAMING TABLE bronze_cdc_clientes 
    (
        CONSTRAINT chave_valida   
        EXPECT (cliente_id IS NOT NULL) ON VIOLATION DROP ROW,
        CONSTRAINT operacao_valida EXPECT (operacao IN ('INSERT','UPDATE','DELETE'))
    )
    COMMENT 'Eventos de CDC de clientes, como chegaram da origem'
    
    AS SELECT *
        FROM STREAM(cdc_clientes_raw);