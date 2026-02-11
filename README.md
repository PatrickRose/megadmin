# Team 12 Software Hut Group Project

## About the project
Our Client wanted a way to quickly and effectively organise his "Megagames" events. This website allows you to create an event as an organiser and supply information such as game brief, location and timetable. You can create players and assign them a role and team and upload briefs with additional information about these things. All relevant information is emailed to each player making event creation quick and efficient.

## Installation and execution
Current project requires to be run using Ruby version 3.3.4 and Rails version 7.0.8.7

1. Clone the repo
    ```bash
    https://git.shefcompsci.org.uk/com3420-2024-25/team12/project
    ```

2. Ensure you have all required gems by opening the terminal and running:
    ```bash
    bundle install
    ```

3. Then ensure you have all necessary package dependencies by running:
    ```bash
    yarn install
    ```

4. To build the project run:
    ```bash
    bundle exec rails s
    ```

5. In another terminal run:
    ```bash
    bin/shakapacker-dev-server 
    ```

6. To handle background tasks which the application relies on, please run this command in a separate terminal:
    ```bash
    RAILS_ENV=demo bin/delayed_job start
    ```

## Contributors
* [Alexander Armes](https://git.shefcompsci.org.uk/aca22abc)
* [Anastasiia Lets](https://git.shefcompsci.org.uk/acb23al)
* [Freddy Cansick](https://git.shefcompsci.org.uk/aca23fc)
* [Hannah Cassidy](https://git.shefcompsci.org.uk/ach22jc)
* [Martin Kuberski](https://git.shefcompsci.org.uk/eia21mpk)
* [Neehru Tumber](https://git.shefcompsci.org.uk/aca22nt)
* [Shiloh Hunt](https://git.shefcompsci.org.uk/ach22mh)
