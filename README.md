![workflow status](https://github.com/impactMarket/impact-market-smart-contracts/workflows/Build/badge.svg)
[![MythXBadge](https://badgen.net/https/api.mythx.io/v1/projects/0b74321a-7ca9-4979-a4d1-ab7211fcc1c3/badge/data?cache=300&icon=https://raw.githubusercontent.com/ConsenSys/mythx-github-badge/main/logo_white.svg)](https://docs.mythx.io/dashboard/github-badges)

# impact-market-smart-contracts

Solidity smart-contracts for impactMarket protocol

## Install

```
$ nvm use
$ yarn
``` 

## Build / Test / Deploy

```
$ yarn build
$ yarn coverage
$ yarn deploy
$ yarn test
```

## Documentation

* Generate with `yarn docgen`
* Navigable HTML documentation from `./docs/index.html`

# Contracts

| Contract                                                              | Purpose                                                                      | Address                                    
|-----------------------------------------------------------------------|------------------------------------------------------------------------------|--------------------------------------------|
| `/airgrab/MerkleDistributor.sol`                                      | Merkle Distributor for the initial token airgrab                             | 0xd2b20e06C19e7b7E7E385b0F1386Cdde8C6dCd2B |
| `/community/CommunityImplementation.sol`                              | A UBI community that is funded by Impact Labs which beneficiaries claim from | 0xEc94c60f17F7f262973f032965534D1137f1202c |
| `/community/CommunityMiddleProxy.sol`                                 | CommunityMiddleProxy                                                         | 0xe8037e4ceEd80EC6D02f482a5A35E0011245FCDC |
| `/community/CommunityAdminProxy.sol`                                  | Proxy contract that orchestrates creation of new Communities                 | 0xd61c407c3A00dFD8C355973f7a14c55ebaFDf6F9 |
| `/governance/ImpactProxyAdmin.sol`                                    | Contract that is in charge of all the proxies                                | 0xFC641CE792c242EACcD545B7bee2028f187f61EC |
| `/governance/PACTDelegator.sol`                                       | Proxy contract that manages creation, execution, cancellation of proposals   | 0x8f8BB984e652Cb8D0aa7C9D6712Ec2020EB1BAb4 |
| `/governance/PACTTimelock.sol`                                        | Timelock that marshalls the execution of governance proposals                | 0xca3171A5FCda4D840Aa375E907b7A1162aDA9379 |
| `/token/DonationMinerProxy.sol`                                       | Proxy vesting contract for non-airgrab distribution of tokens                | 0x1C51657af2ceBA3D5492bA0c5A17E562F7ba6593 |
| `/token/ImpactLabsProxy.sol`                                          | Vesting contract for ImpactLabs distribution of tokens                       | 0x767DA1d208DDA5bc517dcd4ba2A83591D68A5535 |
| `/token/PACTToken.sol`                                                | The Impact Markets cERC-20 token contract                                    | 0x46c9757C5497c5B1f2eb73aE79b6B67D119B0B58 |
| `/token/TreasuryProxy.sol`                                            | Contract that manages the funds                                              | 0xa302dd52a4a85e6778E6A64A0E5EB0e8C76463d6 |
| `/token/TreasuryLPSwapProxy.sol`                                      | Contract that manages the funds                                              | 0xb062e54eBe08d3f720Fc2798f5D6B282df7753ED |
| `/staking/StakingProxy.sol`                                           | Contract that manages the staking                                            | 0x1751e740379FC08b7f0eF6d49183fc0931Bd8179 |
| `/governor/impactMarketCouncil/ImpactMarketCouncilProxy.sol`          | ImpactMarketCouncilProxy                                                     | 0xF2CA11DA5c3668DD48774f3Ce8ac09aFDc24aF3E |
| `/ambassadors/AmbassadorsProxy.sol`                                   | AmbassadorsProxy                                                             | 0x25f58d8C2522dC7E0C53cF8163C837De2415Ba51 |
| `/airdropV2/AirdropV2Proxy.sol`                                       | AirdropV2Proxy                                                               | 0x482E748D452e6ECD86D58E597B673C5E653dAbe9 |
| `/learnAndEarn/LearnAndEarnProxy.sol`                                 | LearnAndEarnProxy                                                            | 0x496F7De1420ad52659e257C7Aa3f79a995274dbc |
| `/deposit/DepositProxy.sol`                                           | DepositProxy                                                                 | 0xF9163f95DF91ad103659cb7C8936Aceb63c7E410 |
| `/microcredit/ImpactMultiSigProxyAdmin.sol`                           | Contract that is admin for some proxies                                      | 0x5e7912f6C052D4D7ec8D6a14330c0c3a538e3f2B |
| `/microcredit/MicrocreditRevenueProxy.sol`                            | Contract that receive all intrest from the microcredit contract              | 0xa75D14c212df85F24ead896747cb1688C1F889D7 |
| `/microcredit/MicrocreditProxy.sol`                                   | Proxy for the microcredit pilot                                              | 0xEa4D67c757a6f50974E7fd7B5b1cc7e7910b80Bb |

