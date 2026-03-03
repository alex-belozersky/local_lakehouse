# Lakehouse DevKit

This project provides an automated **Lakehouse environment** based on **MinIO, Nessie, Trino, and Airflow**.
The setup supports fast provisioning both **locally** and in **VK Cloud**, using scripts, Docker Compose, Packer, Ansible, and Terraform.

### Alex Belozersky

[Telegram](https://t.me/analyticsfromzero)

[Курс - Lakehouse для аналитиков и инженеров данных](https://devhands.ru/lakehouse)

## Repository Structure

* **lakehouse_repo/** – the Lakehouse components (Docker Compose, configs, Trino, MinIO, Nessie, Airflow, DBT, DAGs).
* **scripts/** – automation for dependency installation, environment generation, and lifecycle management of the Lakehouse stack.
* **image/** – Packer + Ansible build for a custom Ubuntu 22.04 image with all required tools preinstalled.
* **terraform/** – Terraform configuration for deploying a ready-to-run Lakehouse VM in VK Cloud.

## Summary

Using this structure, you can deploy a complete Lakehouse environment in minutes-locally or in VK Cloud-through a unified, automated workflow.
When deploying via Terraform, the VM becomes available immediately, but the Lakehouse services continue initializing in the background. Before using the environment, wait until all containers are up and healthy.
