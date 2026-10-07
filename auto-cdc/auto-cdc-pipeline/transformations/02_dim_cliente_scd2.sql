CREATE OR REFRESH STREAMING TABLE dim_cliente_scd2
    COMMENT 'Dimensao de clientes - SCD Tipo 2 (historico completo)';

CREATE FLOW f_dim_cliente_scd2 AS AUTO CDC INTO dim_cliente_scd2
    FROM STREAM(bronze_cdc_clientes)
    KEYS (cliente_id)
    APPLY AS DELETE WHEN operacao = 'DELETE'
    SEQUENCE BY ts
    COLUMNS * EXCEPT (operacao)
    STORED AS SCD TYPE 2
;