from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.bash import BashOperator

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
    dag_id="reporting_layer_dag",
    default_args=default_args,
    description="Run dbt reporting models — final dashboard-ready tables",
    schedule_interval=None,  # triggered by gold_layer_dag
    catchup=False,
    tags=["reporting", "dbt"],
) as dag:

    run_reporting = BashOperator(
        task_id="run_dbt_reporting",
        bash_command=f"{DBT_CMD} --select reporting",
    )

    run_reporting_tests = BashOperator(
        task_id="run_dbt_reporting_tests",
        bash_command=(
            f"cd {DBT_DIR} && dbt test "
            f"--profiles-dir {DBT_DIR} --project-dir {DBT_DIR} "
            "--select reporting"
        ),
    )

    run_reporting >> run_reporting_tests
