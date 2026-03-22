{% macro parse_datetime(datetime_field) %}
  CASE
    -- Case 1: Datetime with pipe-separated data
    WHEN REGEXP_CONTAINS({{ datetime_field }}, r'^\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}\|') THEN
      PARSE_DATETIME('%Y/%m/%d %H:%M:%S', SPLIT({{ datetime_field }}, '|')[SAFE_OFFSET(0)])

    -- Case 2: MM/DD/YYYY HH:MM (non-zero-padded)
    WHEN REGEXP_CONTAINS({{ datetime_field }}, r'^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}$') THEN
      PARSE_DATETIME('%m/%d/%Y %H:%M',
        CONCAT(
          LPAD(SPLIT({{ datetime_field }}, '/')[SAFE_OFFSET(0)], 2, '0'), '/',
          LPAD(SPLIT({{ datetime_field }}, '/')[SAFE_OFFSET(1)], 2, '0'), '/',
          SPLIT(SPLIT({{ datetime_field }}, ' ')[SAFE_OFFSET(0)], '/')[SAFE_OFFSET(2)], ' ',
          SPLIT({{ datetime_field }}, ' ')[SAFE_OFFSET(1)]
        )
      )

    -- Case 3: YYYY/MM/DD HH:MM:SS (standard)
    WHEN REGEXP_CONTAINS({{ datetime_field }}, r'^\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}$') THEN
      PARSE_DATETIME('%Y/%m/%d %H:%M:%S', {{ datetime_field }})

    -- Case 4: ISO 8601
    WHEN REGEXP_CONTAINS({{ datetime_field }}, r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$') THEN
      PARSE_DATETIME('%Y-%m-%dT%H:%M:%S', {{ datetime_field }})

    -- Case 5: YYYY-MM-DD HH:MM:SS
    WHEN REGEXP_CONTAINS({{ datetime_field }}, r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$') THEN
      PARSE_DATETIME('%Y-%m-%d %H:%M:%S', {{ datetime_field }})

    ELSE
      NULL
  END
{% endmacro %}
