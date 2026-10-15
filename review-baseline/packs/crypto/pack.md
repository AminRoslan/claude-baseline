---
pack: crypto
agent: crypto-reviewer
escalate_in_qa_pass: true
---
Enable for: wallets, exchanges, custody, on-chain payments, DeFi front/back ends, NFT platforms, smart-contract repos, anything that signs or broadcasts transactions or holds keys.

Route crypto-reviewer when the diff touches:
- paths/names containing: wallet, key, mnemonic, seed, sign, signer, tx, transaction, nonce, gas, chain, rpc, block, confirm, deposit, withdraw, bridge, token, erc20, spl, contract, abi, address
- smart-contract source (e.g. .sol, .vy, .move, .rs in a contracts dir)
- custody, hot/cold wallet, or key-management code
