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
    "execution_timeout": timedelta(minutes=60),
}

with DAG(
    dag_id="gold_layer_dag",
    default_args=default_args,
    description="Run dbt gold/marts models — produces business-ready aggregates",
    schedule_interval=None,  # triggered by silver_layer_dag
    catchup=False,
    tags=["gold", "marts", "dbt"],
) as dag:

    run_gold = BashOperator(
        task_id="run_dbt_gold",
        bash_command=f"{DBT_CMD} --select marts",
    )

    run_gold_tests = BashOperator(
        task_id="run_dbt_gold_tests",
        bash_command=(
            f"cd {DBT_DIR} && dbt test "
            f"--profiles-dir {DBT_DIR} --project-dir {DBT_DIR} "
            "--select marts"
        ),
    )

    trigger_reporting = TriggerDagRunOperator(
        task_id="trigger_reporting_layer",
        trigger_dag_id="reporting_layer_dag",
        wait_for_completion=True,
        poke_interval=30,
    )

    run_gold >> run_gold_tests >> trigger_reporting
