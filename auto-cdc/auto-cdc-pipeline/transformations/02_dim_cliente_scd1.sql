CREATE OR REFRESH STREAMING TABLE dim_cliente_scd1
    COMMENT 'Dimensao de clientes - SCD Tipo 1 (so o estado atual)';

CREATE FLOW f_dim_cliente_scd1 AS AUTO CDC INTO dim_cliente_scd1
    FROM STREAM(bronze_cdc_clientes)
    KEYS (cliente_id)                          -- chave de negocio
    APPLY AS DELETE WHEN operacao = 'DELETE'   -- como reconhecer um delete
    SEQUENCE BY ts                             -- quem e o evento mais recente
    COLUMNS * EXCEPT (operacao)                -- nao levar a coluna tecnica
    STORED AS SCD TYPE 1
;
