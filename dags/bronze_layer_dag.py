from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

DBT_DIR = "/opt/airflow/dbt"
DBT_CMD = f"cd {DBT_DIR} && dbt run --profiles-dir {DBT_DIR} --project-dir {DBT_DIR}"

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "start_date": datetime(2026, 3, 16),
    "email_on_failure": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(minutes=30),
}

with DAG(
    dag_id="bronze_layer_dag",
    default_args=default_args,
    description="Run dbt bronze models — ingests TheLook public data into bronze layer",
    schedule_interval="0 1 * * *",  # 1 AM UTC daily
    catchup=False,
    tags=["bronze", "ecommerce", "dbt"],
) as dag:

    run_bronze = BashOperator(
        task_id="run_dbt_bronze",
        bash_command=f"{DBT_CMD} --select bronze",
    )

    trigger_silver = TriggerDagRunOperator(
        task_id="trigger_silver_layer",
        trigger_dag_id="silver_layer_dag",
        wait_for_completion=True,
        poke_interval=30,
    )

    run_bronze >> trigger_silver
