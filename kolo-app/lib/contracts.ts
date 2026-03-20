export const cUsdAddress = "0x874069Fa1Eb16d44d622F2e0Ca25eeA172369bC1";

export const defaultKoloGroupAddress =
  process.env.NEXT_PUBLIC_KOLO_GROUP_ADDRESS || "";

export const koloGroupAbi = [
  {
    name: "createGroup",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      {
        name: "_contributionAmount",
        type: "uint256",
      },
      {
        name: "_tokenAddress",
        type: "address",
      },
    ],
    outputs: [],
  },
  {
    name: "joinGroup",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [],
    outputs: [],
  },
  {
    name: "contribute",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      {
        name: "amount",
        type: "uint256",
      },
    ],
    outputs: [],
  },
  {
    name: "contributionAmount",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
      },
    ],
  },
  {
    name: "getMembersCount",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [
      {
        name: "",
        type: "uint256",
      },
    ],
  },
];

export const erc20Abi = [
  {
    name: "approve",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      {
        name: "spender",
        type: "address",
      },
      {
        name: "amount",
        type: "uint256",
      },
    ],
    outputs: [
      {
        name: "",
        type: "bool",
      },
    ],
  },
];
