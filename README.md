# Sadguru Catering OS

Internal business operating system for Sadguru Catering.

## Overview

Sadguru Catering OS is an internal platform designed to centralize
and manage the company's catering business operations.

The platform will eventually cover:

- CRM
- Leads and sales
- Customers
- Events
- Menus
- Recipes
- Kitchen operations
- Inventory
- Procurement
- Vendors
- Workforce
- Logistics
- Finance
- Function-hall partnerships
- Marketing
- Analytics
- Notifications
- Documents
- AI-assisted business intelligence

## Product Type

Internal business operations platform.

## Users

The initial system is designed for fewer than 10 internal company users.

## Architecture

The initial architecture direction is a modular monolith.

## Repository Structure

```text
backend/        Go backend application
frontend/       React frontend application
worker/         Background job processing
database/       Database-related resources
deployments/    Deployment configuration
scripts/        Development and operational scripts
tests/          Integration and E2E tests
docs/           Project documentation
.github/        GitHub automation

### Backend

Go

### Frontend

React + TypeScript

### Database

PostgreSQL

### Cache

Redis where justified

### Deployment

Docker

### Storage

Object storage for documents and images.

## Version

Current version:

`1.0.1`

## Development Status

Project initialization.

Business modules have not yet been implemented.

## Documentation

See the `docs/` directory.

## Versioning

See:

`docs/VERSIONING.md`

## License

Proprietary software.