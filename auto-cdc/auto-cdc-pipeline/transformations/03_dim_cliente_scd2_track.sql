CREATE OR REFRESH STREAMING TABLE dim_cliente_scd2_track
  COMMENT 'SCD Tipo 2 versionando apenas a coluna segmento';

CREATE FLOW f_dim_cliente_scd2_track AS AUTO CDC INTO dim_cliente_scd2_track
    FROM STREAM(bronze_cdc_clientes)
    KEYS (cliente_id)
    APPLY AS DELETE WHEN operacao = 'DELETE'
    SEQUENCE BY ts
    COLUMNS * EXCEPT (operacao)
    STORED AS SCD TYPE 2
    TRACK HISTORY ON segmento
;