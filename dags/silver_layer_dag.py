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
    "execution_timeout": timedelta(minutes=45),
}

with DAG(
    dag_id="silver_layer_dag",
    default_args=default_args,
    description="Run dbt silver/staging models — cleans and standardises bronze data",
    schedule_interval=None,  # triggered by bronze_layer_dag
    catchup=False,
    tags=["silver", "staging", "dbt"],
) as dag:

    run_silver = BashOperator(
        task_id="run_dbt_silver",
        bash_command=f"{DBT_CMD} --select staging",
    )

    run_silver_tests = BashOperator(
        task_id="run_dbt_silver_tests",
        bash_command=(
            f"cd {DBT_DIR} && dbt test "
            f"--profiles-dir {DBT_DIR} --project-dir {DBT_DIR} "
            "--select staging"
        ),
    )

    trigger_gold = TriggerDagRunOperator(
        task_id="trigger_gold_layer",
        trigger_dag_id="gold_layer_dag",
        wait_for_completion=True,
        poke_interval=30,
    )

    run_silver >> run_silver_tests >> trigger_gold
