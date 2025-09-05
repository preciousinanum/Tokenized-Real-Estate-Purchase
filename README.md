# 🏠 PropChain - Tokenized Real Estate Protocol

> 🚀 **Fractional Real Estate Ownership Made Simple**

PropChain is a revolutionary Clarity smart contract that enables fractional ownership of real estate through digital tokens on the Stacks blockchain. Transform real estate investment by breaking down property barriers and creating liquid, accessible investment opportunities.

## ✨ Features

- 🏢 **Property Tokenization**: Convert real estate into fungible tokens
- 💰 **Fractional Ownership**: Own percentages of properties instead of whole properties  
- 🗳️ **Governance Voting**: Token holders vote on property decisions
- 💸 **Dividend Distribution**: Automatic rental income distribution
- 🔄 **Token Trading**: Transfer ownership stakes between users
- 📊 **Ownership Tracking**: Real-time ownership percentage calculations

## 🛠️ Installation

```bash
# Clone the repository
git clone https://github.com/preciousinanum/Tokenized-Real-Estate-Purchase
cd Tokenized-Real-Estate-Purchase

# Install dependencies
npm install

# Check contract compilation
clarinet check
```

## 📋 Contract Functions

### 🏗️ Property Management

#### `create-property`
Creates a new tokenized property.
```clarity
(create-property total-value total-tokens location description)
```
- **total-value**: Property value in microSTX
- **total-tokens**: Number of tokens representing the property
- **location**: Property address/location
- **description**: Property details

#### `update-property-status`
Activates or deactivates a property.
```clarity
(update-property-status property-id is-active)
```

### 💎 Token Operations

#### `purchase-tokens`
Buy fractional ownership tokens.
```clarity
(purchase-tokens property-id token-amount)
```

#### `transfer-tokens`
Transfer ownership tokens to another user.
```clarity
(transfer-tokens property-id token-amount recipient)
```

### 🗳️ Governance

#### `create-proposal`
Create a governance proposal for property decisions.
```clarity
(create-proposal property-id description)
```

#### `vote-on-proposal`
Vote on property proposals with your token weight.
```clarity
(vote-on-proposal property-id proposal-id vote)
```

### 💰 Dividends

#### `distribute-dividends`
Distribute rental income to token holders (property owner only).
```clarity
(distribute-dividends property-id total-dividend)
```

#### `claim-dividends`
Claim your share of distributed dividends.
```clarity
(claim-dividends property-id)
```

## 📖 Usage Example

```clarity
;; 1. Create a property worth 1,000,000 microSTX with 10,000 tokens
(create-property u1000000 u10000 u"123 Main St, NYC" u"Luxury downtown apartment")

;; 2. Purchase 100 tokens (1% ownership)
(purchase-tokens u1 u100)

;; 3. Create a renovation proposal
(create-proposal u1 u"Install solar panels to increase property value")

;; 4. Vote on the proposal
(vote-on-proposal u1 u1 true)

;; 5. Distribute rental income
(distribute-dividends u1 u50000)

;; 6. Claim your dividend share
(claim-dividends u1)
```

## 🔍 Read-Only Functions

- `get-property`: Get property details
- `get-property-ownership`: Check ownership amounts
- `get-property-proposal`: View governance proposals
- `calculate-ownership-percentage`: Calculate ownership percentage
- `get-property-dividends`: View dividend information

## 🎯 Key Benefits

- 🌍 **Global Access**: Invest in real estate from anywhere
- 💧 **Liquidity**: Trade property tokens instantly
- 📉 **Lower Barriers**: Start investing with smaller amounts
- 🤝 **Transparency**: All transactions on-chain and auditable
- 🏛️ **Democratic Governance**: Token holders control property decisions

## ⚡ Getting Started

1. Deploy the PropChain contract to Stacks testnet
2. Create your first tokenized property using `create-property`
3. Allow investors to purchase fractional ownership
4. Enable governance voting for property decisions
5. Distribute rental income as dividends

## 🔒 Security Features

- Owner-only property creation
- Token holder governance rights
- Dividend claim tracking
- Transfer validation
- Voting period enforcement

## 🚀 Future Enhancements

- NFT integration for unique property certificates
- Cross-chain bridge support
- Automated property valuation
- DeFi lending integration
- Real estate marketplace

---

**Built with ❤️ using Clarity and Stacks blockchain**
