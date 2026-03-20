"use client";

import { formatUnits, isAddress } from "viem";
import { useState } from "react";
import { WalletConnectButton } from "@/components/WalletConnectButton";
import {
  cUsdAddress,
  erc20Abi,
  koloGroupAbi,
  defaultKoloGroupAddress,
} from "@/lib/contracts";
import {
  useAccount,
  useBalance,
  useContractRead,
  useContractWrite,
  useNetwork,
  usePrepareContractWrite,
} from "wagmi";

const CELO_ALFAJORES_CHAIN_ID = 44787;

export default function JoinAjoPage() {
  const { address, isConnected } = useAccount();
  const { chain } = useNetwork();
  const { data: cusdBalance } = useBalance({
    address,
    token: cUsdAddress,
    watch: true,
  });
  const [contractAddress, setContractAddress] = useState(
    defaultKoloGroupAddress
  );
  const [status, setStatus] = useState<string | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  const contractIsValid = isAddress(contractAddress);

  const { data: contributionAmount } = useContractRead({
    address: contractIsValid ? (contractAddress as `0x${string}`) : undefined,
    abi: koloGroupAbi,
    functionName: "contributionAmount",
    enabled: contractIsValid,
    watch: true,
  });

  const contributionDisplay = contributionAmount
    ? formatUnits(contributionAmount, 18)
    : "0.00";

  const parsedContribution = contributionAmount ?? 0n;

  const { config: joinConfig } = usePrepareContractWrite({
    address: contractIsValid ? (contractAddress as `0x${string}`) : undefined,
    abi: koloGroupAbi,
    functionName: "joinGroup",
    enabled: contractIsValid,
  });

  const { write: joinGroup, isLoading: joining } = useContractWrite({
    ...joinConfig,
    onSuccess: () => setStatus("You’ve joined the grupo."),
    onError: (error) =>
      setStatus(error?.message ?? "Unable to join the group at this time."),
  });

  const { config: approveConfig } = usePrepareContractWrite({
    address: cUsdAddress,
    abi: erc20Abi,
    functionName: "approve",
    args:
      contractIsValid && parsedContribution > 0n
        ? [(contractAddress as `0x${string}`), parsedContribution]
        : undefined,
    enabled: contractIsValid && parsedContribution > 0n,
  });

  const { write: approve } = useContractWrite({
    ...approveConfig,
    onError: (error) =>
      setStatus(error?.message ?? "Approval failed to submit."),
  });

  const { config: contributeConfig } = usePrepareContractWrite({
    address: contractIsValid ? (contractAddress as `0x${string}`) : undefined,
    abi: koloGroupAbi,
    functionName: "contribute",
    args:
      contractIsValid && parsedContribution > 0n
        ? [parsedContribution]
        : undefined,
    enabled: contractIsValid && parsedContribution > 0n,
  });

  const { write: contribute } = useContractWrite({
    ...contributeConfig,
    onError: (error) =>
      setStatus(error?.message ?? "Contribution transaction failed."),
  });

  const handleContribution = async () => {
    if (!approve || !contribute) {
      setStatus("Waiting for the prepared transactions.");
      return;
    }

    setIsProcessing(true);
    setStatus("Approving cUSD...");
    try {
      const approvalTx = await approve();
      await approvalTx.wait();
      setStatus("Submitting contribution...");
      const contributionTx = await contribute();
      await contributionTx.wait();
      setStatus("First contribution confirmed!");
    } catch (error: unknown) {
      const fallbackMessage =
        error instanceof Error ? error.message : "Contribution workflow failed.";
      setStatus(fallbackMessage);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <main className="min-h-screen flex flex-col gap-8 px-6 py-10 text-slate-50">
      <section className="glass-card space-y-6">
        <header className="flex flex-col gap-2">
          <p className="text-sm uppercase tracking-[0.3em] text-slate-400">
            Join Ajo
          </p>
          <h1 className="text-3xl font-semibold text-white">
            Connect your wallet, approve cUSD, and contribute
          </h1>
          <p className="text-slate-300">
            MetaMask and Valora work out of the box. RainbowKit handles the
            connectors while this page walks you through the join + contribute
            flow.
          </p>
        </header>
        <WalletConnectButton />
        {!isConnected && (
          <p className="text-sm text-slate-400">
            Connect a wallet using MetaMask or Valora before interacting.
          </p>
        )}
        {chain?.id !== CELO_ALFAJORES_CHAIN_ID && (
          <p className="text-sm text-amber-300">
            Switch your wallet to Celo Alfajores (chain ID 44787) to submit
            transactions.
          </p>
        )}

        <div className="space-y-4 rounded-2xl border border-white/10 bg-white/5 p-6">
          <label className="block text-sm font-semibold text-slate-300">
            KoloGroup contract address
          </label>
          <input
            value={contractAddress}
            onChange={(event) => setContractAddress(event.target.value.trim())}
            placeholder="0x..."
            className="w-full rounded-lg border border-white/20 bg-slate-900/40 px-4 py-3 text-sm text-white placeholder:text-slate-500 focus:border-cyan-400 focus:outline-none"
          />
          {!contractIsValid && contractAddress && (
            <p className="text-xs text-rose-300">
              Enter a valid Alfajores contract address before joining.
            </p>
          )}
        </div>

        <div className="rounded-2xl border border-white/10 bg-white/5 p-6 text-sm text-slate-300">
          <p>
            Contribution amount = <span className="font-semibold text-white">{contributionDisplay} cUSD</span>.
            This value is pulled from the smart contract in real time.
          </p>
        </div>

        <div className="flex flex-col gap-4">
          <button
            className="w-full rounded-2xl border border-cyan-500/70 bg-transparent px-4 py-3 text-sm font-semibold uppercase tracking-[0.3em] text-cyan-300 transition hover:bg-cyan-500/10 disabled:opacity-40"
            disabled={!isConnected || !joinGroup || !contractIsValid}
            onClick={() => {
              setStatus(null);
              joinGroup?.();
            }}
          >
            {joining ? "Joining…" : "Join group"}
          </button>

          <button
            className="w-full rounded-2xl bg-cyan-500 px-4 py-3 text-sm font-semibold uppercase tracking-[0.3em] text-slate-950 transition hover:bg-cyan-400 disabled:opacity-40"
            disabled={
              !isConnected ||
              !approve ||
              !contribute ||
              !contractIsValid ||
              parsedContribution === 0n ||
              isProcessing
            }
            onClick={handleContribution}
          >
            {isProcessing ? "Processing…" : "Contribute cUSD"}
          </button>
        </div>
        {status && <p className="text-sm text-cyan-200">{status}</p>}
        {cusdBalance && (
          <p className="text-xs text-slate-500">
            cUSD balance: {cusdBalance.formatted} {cusdBalance.symbol}
          </p>
        )}
      </section>
    </main>
  );
}

