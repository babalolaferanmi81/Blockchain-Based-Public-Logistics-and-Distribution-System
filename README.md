# Blockchain-Based Public Logistics and Distribution System

A comprehensive smart contract system for managing public sector logistics and distribution operations on the Stacks blockchain.

## Overview

This system consists of five interconnected smart contracts that manage different aspects of public logistics:

1. **Government Supply Chain Management** - Coordinates procurement and distribution of government supplies
2. **Public Transportation Logistics** - Manages routing, scheduling, and maintenance of public transit systems
3. **Emergency Supply Distribution** - Coordinates distribution of supplies during disasters and emergencies
4. **Mail and Package Delivery Coordination** - Manages postal services and package delivery in rural areas
5. **Freight and Cargo Transportation** - Coordinates movement of goods through ports, airports, and highways

## Features

### Government Supply Chain Management
- Procurement request management
- Supplier registration and verification
- Inventory tracking and management
- Distribution coordination
- Budget allocation and tracking

### Public Transportation Logistics
- Route management and optimization
- Vehicle scheduling and maintenance
- Passenger capacity tracking
- Service disruption management
- Performance metrics

### Emergency Supply Distribution
- Emergency declaration and response
- Supply inventory for disasters
- Distribution center coordination
- Priority allocation system
- Real-time status tracking

### Mail and Package Delivery Coordination
- Package registration and tracking
- Delivery route optimization
- Rural area service coordination
- Delivery confirmation system
- Service level management

### Freight and Cargo Transportation
- Cargo manifest management
- Port and airport coordination
- Highway logistics planning
- Container tracking
- Transportation scheduling

## Contract Architecture

Each contract is designed to be:
- **Self-contained**: No cross-contract dependencies
- **Transparent**: All operations are publicly auditable
- **Efficient**: Optimized for gas usage
- **Secure**: Built-in access controls and validation

## Data Types

The system uses standard Clarity data types:
- `uint` for quantities, IDs, and timestamps
- `principal` for addresses and identities
- `(string-ascii 50)` for names and short descriptions
- `(string-ascii 200)` for longer descriptions
- `bool` for status flags
- `(optional T)` for nullable values

## Error Codes

Each contract defines specific error codes:
- `u100-u199`: Input validation errors
- `u200-u299`: Authorization errors
- `u300-u399`: State errors
- `u400-u499`: Business logic errors

## Getting Started

### Prerequisites
- Clarinet CLI
- Node.js and npm
- Stacks wallet for testing

### Installation

\`\`\`bash
git clone <repository-url>
cd public-logistics-blockchain
npm install
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Government Supply Chain
\`\`\`clarity
;; Create procurement request
(contract-call? .government-supply-chain create-procurement-request
"Office Supplies"
"Pens, paper, folders for Q1"
u50000)

;; Register supplier
(contract-call? .government-supply-chain register-supplier
'SP1SUPPLIER
"Office Supply Co"
"office-supplies")
\`\`\`

### Public Transportation
\`\`\`clarity
;; Add new route
(contract-call? .public-transportation add-route
"Route 101"
"Downtown to Airport"
u45)

;; Schedule vehicle
(contract-call? .public-transportation schedule-vehicle
u1
u1
u800
u50)
\`\`\`

## Security Considerations

- All functions include proper authorization checks
- Input validation prevents invalid data entry
- State transitions are carefully controlled
- Emergency functions are restricted to authorized personnel

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License.
