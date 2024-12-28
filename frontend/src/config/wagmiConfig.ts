import { http } from 'wagmi';
import { phantomWallet } from '@rainbow-me/rainbowkit/wallets'
import { connectorsForWallets, getDefaultWallets } from '@rainbow-me/rainbowkit'
import { getDefaultConfig } from '@rainbow-me/rainbowkit'
const { wallets } = getDefaultWallets()
const appName = 'FHE Voting'
const projectId = '953b8aabd42f299570ac0cb2509db530'
const connectors = connectorsForWallets(
  [
    ...wallets,
    {
      groupName: 'Popular',
      wallets: [phantomWallet],
    },
  ],
  {
    appName,
    projectId,
  },
)
import type { Chain } from 'viem'

const fhenix = {
  id: 8008135,
  name: 'Fhenix',
  nativeCurrency: { name: 'tFHE', symbol: 'FHE', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://api.helium.fhenix.zone'] },
  },
  blockExplorers: {
    default: { name: 'Explorer', url: 'https://explorer.helium.fhenix.zone' },
  },
  contracts: {
      ensRegistry: {
        address: '0x0',
    },
    ensUniversalResolver: {
      address: '0x0',
      blockCreated: 16773775,
    },
    multicall3: {
      // not supported?
      address: '0x',
      blockCreated: 8123891232939923,
    },
  },
} as const satisfies Chain

export const wagmiConfig = getDefaultConfig({
  transports: {
    [fhenix.id]: http(),
  },
    appName: 'My-first-dapp',
    projectId: projectId,
    chains: [fhenix],
    ssr: true,
  });

// testnet
// export const votingAddress = '0x738353084Bb884575AB84Cc168e7f85BF408133B'
export const votingAddress = '0x60BFd99208db9540B019f1FB7bC2452EEc494E63'
// export const votingAddress = '0x5A56A5e5E25372b885f5CeC650E6c593711a2B91'

// localhost
// export const votingAddress = "0xbeb4eF1fcEa618C6ca38e3828B00f8D481EC2CC2"