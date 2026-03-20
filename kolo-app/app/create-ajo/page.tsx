"use client";

import { parseUnits, isAddress } from "viem";
import { useMemo, useState } from "react";
import { WalletConnectButton } from "@/components/WalletConnectButton";
import {
  koloGroupAbi,
  cUsdAddress,
  defaultKoloGroupAddress,
} from "@/lib/contracts";
import { useAccount, useContractWrite, usePrepareContractWrite } from "wagmi";

export default function CreateAjoPage() {
  const { isConnected } = useAccount();
  const [contributionAmount, setContributionAmount] = useState("25");
  const [memberCount, setMemberCount] = useState("6");
  const [contractAddress, setContractAddress] = useState(
    defaultKoloGroupAddress
  );
  const [message, setMessage] = useState<string | null>(null);

  const parsedContribution = useMemo(() => {
    if (!contributionAmount) return undefined;
    try {
      return parseUnits(contributionAmount, 18);
    } catch {
      return undefined;
    }
  }, [contributionAmount]);

  const contractIsValid = isAddress(contractAddress);

  const { config } = usePrepareContractWrite({
    address: contractIsValid ? (contractAddress as `0x${string}`) : undefined,
    abi: koloGroupAbi,
    functionName: "createGroup",
    args: parsedContribution
      ? [parsedContribution, cUsdAddress]
      : undefined,
    enabled: Boolean(parsedContribution) && contractIsValid,
  });

  const { write, isLoading } = useContractWrite({
    ...config,
    onSuccess: () => setMessage("Club creation transaction submitted."),
    onError: (error) =>
      setMessage(error?.message || "Failed to submit creation transaction."),
  });

  return (
    <main className="min-h-screen flex flex-col gap-8 px-6 py-10 text-slate-50">
      <section className="glass-card space-y-6">
        <header className="flex flex-col gap-2">
          <p className="text-sm uppercase tracking-[0.3em] text-slate-400">
            Create Ajo
          </p>
          <h1 className="text-3xl font-semibold text-white">
            Launch your rotating savings group
          </h1>
          <p className="text-slate-300">
            Set the contribution size, expected member count, and mint the
            Alfajores KoloGroup contract. Wallet connection via MetaMask or
            Valora is required before sending the transaction.
          </p>
        </header>
        <WalletConnectButton />

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
              Enter a valid contract address deployed on Alfajores.
            </p>
          )}
        </div>

        <form
          className="space-y-4"
          onSubmit={(event) => {
            event.preventDefault();
            setMessage(null);
            write?.();
          }}
        >
          <div className="grid gap-4 md:grid-cols-2">
            <label className="space-y-2 text-sm text-slate-300">
              Contribution amount (cUSD)
              <input
                type="number"
                step="0.01"
                min="0"
                value={contributionAmount}
                onChange={(event) => setContributionAmount(event.target.value)}
                className="w-full rounded-lg border border-white/20 bg-slate-900/40 px-4 py-3 text-sm text-white focus:border-cyan-400 focus:outline-none"
              />
            </label>
            <label className="space-y-2 text-sm text-slate-300">
              Member count (for planning)
              <input
                type="number"
                min="2"
                value={memberCount}
                onChange={(event) => setMemberCount(event.target.value)}
                className="w-full rounded-lg border border-white/20 bg-slate-900/40 px-4 py-3 text-sm text-white focus:border-cyan-400 focus:outline-none"
              />
            </label>
          </div>

          <button
            className="w-full rounded-2xl bg-cyan-500 px-4 py-3 text-sm font-semibold uppercase tracking-[0.2em] text-slate-950 transition hover:bg-cyan-400 disabled:opacity-40"
            disabled={
              !isConnected || isLoading || !contractIsValid || !write
            }
          >
            {isLoading ? "Submitting…" : "Create group"}
          </button>
          {message && (
            <p className="text-sm text-cyan-200">{message}</p>
          )}
          <p className="text-xs text-slate-500">
            Member count is for your bookkeeping; the smart contract tracks only
            contributions and payouts.
          </p>
        </form>
      </section>
    </main>
  );
}
