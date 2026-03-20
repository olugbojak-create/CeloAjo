import Link from "next/link";
import { WalletConnectButton } from "@/components/WalletConnectButton";

const actions = [
  {
    label: "Create Ajo",
    description: "Define the contribution amount and invite the first members.",
    href: "/create-ajo",
  },
  {
    label: "Join Ajo",
    description: "Connect your wallet, approve cUSD, and submit round one.",
    href: "/join-ajo",
  },
  {
    label: "Contract telemetry",
    description: "Track members, rounds, and payouts in your Foundry workspace.",
    href: "https://github.com",
  },
];

export default function Home() {
  return (
    <main className="min-h-screen flex flex-col gap-10 px-6 py-10">
      <section className="glass-card flex flex-col gap-6">
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-sm uppercase tracking-[0.3em] text-slate-400">
              Celo Alfajores
            </p>
            <h1 className="mt-3 text-4xl font-semibold text-white">
              Kolo Group
            </h1>
            <p className="mt-4 text-lg text-slate-300">
              Create and join a rotating savings group (ajo) powered by KoloGroup
              on Celo Alfajores. Manage contribution scheduling, cUSD approvals,
              and member count from this single dashboard.
            </p>
          </div>
          <WalletConnectButton />
        </div>
        <div className="grid gap-4 rounded-2xl border border-white/10 p-6 text-sm text-slate-300 md:grid-cols-3">
          <p>
            Contribution amount locks in your round. Every member must fund cUSD
            before the payout.
          </p>
          <p>
            Wallets use MetaMask or Valora via RainbowKit. Set your preferred
            connector any time.
          </p>
          <p className="text-xs text-slate-500">
            The KoloGroup contract lives in the root Solidity folder. Deploy to
            Alfajores, then paste the address into each page for writes.
          </p>
        </div>
      </section>

      <section className="glass-card space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-semibold text-white">Quick Actions</h2>
          <p className="text-sm uppercase tracking-[0.3em] text-slate-500">
            Workflow
          </p>
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          {actions.map((action) => (
            <Link key={action.label} href={action.href}>
              <article className="group flex flex-col justify-between gap-4 rounded-2xl border border-white/10 bg-white/5 p-6 transition hover:border-cyan-400/70 hover:bg-white/10">
                <h3 className="text-xl font-semibold text-white">{action.label}</h3>
                <p className="text-sm text-slate-300">{action.description}</p>
                <p className="text-xs text-cyan-300 group-hover:underline">
                  Launch {"\u2192"}
                </p>
              </article>
            </Link>
          ))}
        </div>
      </section>
    </main>
  );
}
