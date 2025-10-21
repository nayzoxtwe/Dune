import { DemoChatSurface } from '@dune/ui';

export default function HomePage() {
  return (
    <main className="min-h-screen bg-[#0B0B0F] text-neutral-200">
      <section className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-10">
        <header className="space-y-2">
          <p className="text-sm uppercase tracking-[0.35em] text-neutral-500">Prototype</p>
          <h1 className="text-3xl font-semibold text-white">Dune Messenger</h1>
          <p className="text-neutral-400">
            Messagerie sécurisée inspirée de LINE avec QR pairing, économie de coins, et contrôles parentaux nocturnes.
          </p>
        </header>
        <DemoChatSurface />
      </section>
    </main>
  );
}
