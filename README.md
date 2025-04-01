# cyfrin-foundry-smart-contract-lottery

This is a section of the [Cyfrin Foundry Solidity Course](https://github.com/Cyfrin/foundry-full-course-cu?tab=readme-ov-file#foundry-fundamentals-section-4-foundry-smart-contract-lottery).

This project implements a simple raffle contract. Players can enter the raffle with a specified amount of ETH.
The raffle selects a winner using Chainlink VRF after a predefined amount of has passed and there's at least one entrant.
When a winner is selecter the raffle resets and players can enter again for a new round. The raffle is automated via Chainlink Automation.

Interactions on Sepolia testnet:
- [contract: Raffle contract](https://sepolia.etherscan.io/address/0x537d451c452fFaFc7637e8d71368EbAF48284584)
- [transaction: Enter Raffle](https://sepolia.etherscan.io/tx/0xa663db94ca4c2ff8d94a028a525b60195cffb1afe029dd1accdfd5c283c4d6a3)
- [transaction: Fulfill Random Words (this picks the winner and sends the prize)](https://sepolia.etherscan.io/tx/0xf6c1f84b90bbab1f5e14c823b481631da5a12b40d6707b34aca1766d18417a3b)
- [Chainlink Automation Upkeep](https://automation.chain.link/sepolia/89765726916605354925277102690966162377993631043438225526958487239146205165087)
