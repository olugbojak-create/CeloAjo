import { configureChains, createConfig } from "wagmi";
import { jsonRpcProvider } from "wagmi/providers/jsonRpc";
import { MetaMaskConnector } from "@wagmi/connectors/metaMask";
import { InjectedConnector } from "@wagmi/connectors/injected";

const alfajoresRpc =
  process.env.NEXT_PUBLIC_ALFAJORES_RPC ||
  "https://alfajores-forno.celo-testnet.org";

export const alfajoresChain = {
  id: 44787,
  name: "Celo Alfajores",
  network: "alfajores",
  nativeCurrency: { name: "CELO", symbol: "CELO", decimals: 18 },
  rpcUrls: {
    default: {
      http: [alfajoresRpc],
    },
  },
  blockExplorers: {
    default: { name: "Explorer", url: "https://explorer.celo.org/alfajores" },
  },
  testnet: true,
} as const;

const { chains, publicClient } = configureChains(
  [alfajoresChain],
  [
    jsonRpcProvider({
      rpc: () => ({ http: alfajoresRpc }),
    }),
  ]
);

export const wagmiConfig = createConfig({
  autoConnect: true,
  connectors: [
    new MetaMaskConnector({ chains }),
    new InjectedConnector({
      chains,
      options: { name: "Valora", shimDisconnect: true },
    }),
  ],
  publicClient,
});

export { chains };
