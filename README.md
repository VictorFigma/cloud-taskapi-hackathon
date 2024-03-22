# About the project
You can check the hackathon details here: [here](challenge.md).

# TODO


# How to install
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

# How to run
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











    pip freeze > requirements.txt