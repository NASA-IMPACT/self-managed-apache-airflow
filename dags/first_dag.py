from airflow import DAG
import pendulum
from airflow.operators.python import PythonOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.bash import BashOperator


def say_hello_task():
    print("Hello world!")
    return 55


def operation_gdal_task():
    print("nott really")
    return 10


with DAG(
        dag_id="say_hello",
        start_date=pendulum.today("UTC").add(hours=-1),
        schedule_interval=None,
        catchup=False,
        description="This DAG says Hello",
        tags=["Airflow", "101"]

) as dag:
    say_hello_t = PythonOperator(
        task_id="say_hello_t",
        python_callable=say_hello_task
    )
    get_things = BashOperator(
        task_id="This_bash",
        bash_command='echo "Default queue"'
    )

    get_things2 = BashOperator(
        task_id="This_bash_q2",
        bash_command='echo "Default queue"'
    )
    get_gdal = BashOperator(

        task_id="This_gdal",
        bash_command='echo "GDAL queue"'
    )
    operation_gdal = PythonOperator(

        task_id="operation_gdal",
        python_callable=operation_gdal_task
    )
    operation_gdal_default = PythonOperator(

        task_id="operation_gdal_default",
        python_callable=operation_gdal_task
    )
    start = EmptyOperator(
        task_id="start"
    )
    end = EmptyOperator(
        task_id="end"
    )
    start >> say_hello_t >> get_things >> get_things2 >> get_gdal >> operation_gdal >> operation_gdal_default >> end
