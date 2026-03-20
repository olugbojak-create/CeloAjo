"use client";

import { useMemo } from "react";
import { useAccount, useConnect, useDisconnect } from "wagmi";

const connectorDescriptions: Record<string, string> = {
  metaMask: "MetaMask (browser)",
  injected: "Valora / Injected",
};

export function WalletConnectButton() {
  const { isConnected, address, isConnecting } = useAccount();
  const { connect, connectors, pendingConnector } = useConnect();
  const { disconnect } = useDisconnect();

  const shortAddress = useMemo(() => {
    if (!address) return "";
    return `${address.slice(0, 6)}…${address.slice(-4)}`;
  }, [address]);

  if (isConnected) {
    return (
      <div className="flex items-center gap-3 rounded-2xl border border-cyan-500/60 bg-white/5 px-4 py-2 text-sm text-cyan-200">
        <span>Connected {shortAddress}</span>
        <button
          onClick={() => disconnect()}
          className="rounded-full bg-rose-500 px-3 py-1 text-xs font-semibold uppercase tracking-[0.3em] text-white transition hover:bg-rose-400"
        >
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-wrap gap-2 text-sm text-slate-200">
      {connectors.map((connector) => (
        <button
          key={connector.id}
          onClick={() => connect({ connector })}
          disabled={!connector.ready}
          className="flex-1 min-w-[200px] rounded-2xl border border-white/20 bg-white/5 px-4 py-3 text-left font-semibold uppercase tracking-[0.2em] text-slate-200 transition hover:border-cyan-400 hover:bg-white/10 disabled:opacity-40 sm:flex-none"
        >
          {isConnecting && pendingConnector?.id === connector.id
            ? "Connecting…"
            : connector.name}
          <p className="text-xs font-normal lowercase text-slate-400">
            {connectorDescriptions[connector.id] || "Connect wallet"}
          </p>
        </button>
      ))}
    </div>
  );
}
