# About the Project
This is a "ServerlessTasker" program that stores tasks using an API (TaskAPI). This project was developed as a solution for a hackathon; you can check the rules [here](challenge.md).

# How to Install
1. Install [Terraform](https://developer.hashicorp.com/terraform/install).

2. Install [Docker](https://docs.docker.com/get-docker/) and [LocalStack Docker Extension](https://docs.localstack.cloud/user-guide/tools/localstack-docker-extension/).

3. Clone this repository locally.
    ```bash
    git clone git@github.com:VictorFigma/cloud-taskapi-hackathon.git
    ```
4. (Optional) Create a virtual enviroment and activate it.<br>
    Creation
    ```bash
    python3 -m venv env 
    ```
    Activation
    ```
    Linux: source env/bin/activate
    Windows: .\env\Scripts\activate
    ```
5. Install the requirements.
    ```bash
    pip install -r requirements.txt
    ```

# How to Run
1. Run a LocalStack container (from another terminal).
    ```bash
    docker run --rm -it -p 4566:4566 -p 4571:4571 -v /var/run/docker.sock:/var/run/docker.sock localstack/localstack
    ```
2. Move to the Terraform folder
    ```bash
    cd .\Infraestructure\Terraform\      
    ```
3. Start Terraform
    ```bash
    terraform init     
    ```
4. Apply Terraform
    ```bash
    terraform apply     
    ```

# What Does the Program Do?

- Stores tasks via **POST** to `http://localhost:4566/createtask`. You must specify the following fields: `task_name`, `cron_expression`.
- Retrieves the list of stored tasks via **GET**: `http://localhost:4566/listtask`.
- Automatically creates a txt file in a S3 bucket every minute.

# Contribution and State of Development
This program was developed during the course of an individual hackathon, and no PRs are accepted. This project successfully achieved objectives 1 & 2, and also partially 3 & 4. Due to time restrictions, it is unfinished, and I no longer intend to further develop it. However, feel free to fork it and continue yourself. I have not added any license restrictions beyond [those of the hackathon](https://github.com/nuwe-io/nuwehack-cloud-tasker).