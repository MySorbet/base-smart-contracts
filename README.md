# My Sorbet Smart Contracts

This repository contains the base smart contracts for the My Sorbet project. These contracts are designed to facilitate various functionalities such as escrow services, token management, and treasury operations on the Base blockchain.

## Overview

The smart contracts include functionalities for managing freelance agreements, token transactions, and treasury operations. The contracts are written in Solidity and deployed using Hardhat.

## Features

- **Escrow Services**: Securely hold funds until conditions are met.
- **Treasury Operations**: Manage funds and distributions.

## Installation

To install and deploy the smart contracts, follow these steps:

1. **Clone the repository**:
    ```sh
    git clone https://github.com/MySorbet/base-smart-contracts.git
    cd base-smart-contracts
    ```

2. **Install dependencies**:
    ```sh
    npm install
    ```

3. **Compile the contracts**:
    ```sh
    npx hardhat compile
    ```

4. **Deploy the contracts**:
    ```sh
    npx hardhat run scripts/deploy.js --network <network-name>
    ```


## Environment Variables

Create a `.env` file in the root directory and add the following variables:

```dotenv
PRIVATE_KEY='your-private-key'
PRIVATE_KEY1='another-private-key'
TOKEN_ADDRESS='your-token-address'
TREASURY_ADDRESS='your-treasury-address'
