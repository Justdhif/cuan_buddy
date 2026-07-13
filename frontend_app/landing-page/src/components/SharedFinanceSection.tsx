import { useTranslation } from 'react-i18next';
import { Users2, ArrowRightLeft, UserCheck } from 'lucide-react';

export default function SharedFinanceSection() {
  const { t } = useTranslation();

  return (
    <section className="py-24 bg-canvas-soft dark:bg-brand-dark-900/40 transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Left Text / Info Column - 6 cols */}
          <div className="lg:col-span-6 space-y-6">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary-bg-subdued-hover/40 border border-primary/20 text-primary-deep dark:text-primary-soft text-[11px] font-semibold tracking-wider uppercase">
              <Users2 size={12} />
              Fitur Unggulan • Featured Feature
            </div>
            
            <h2 className="font-display-xl text-ink dark:text-canvas text-3xl sm:text-4xl leading-tight">
              {t('shared_finance.title')}
            </h2>
            
            <p className="text-[16px] text-ink-secondary dark:text-canvas-soft/80 leading-relaxed font-light">
              {t('shared_finance.subtitle')}
            </p>

            <ul className="space-y-4 pt-2">
              {[1, 2, 3, 4].map((idx) => (
                <li key={idx} className="flex items-start gap-3">
                  <div className="w-5 h-5 rounded-full bg-primary/10 flex items-center justify-center shrink-0 mt-0.5">
                    <span className="text-primary dark:text-primary-soft text-[10px] font-bold">✓</span>
                  </div>
                  <span className="text-[15px] text-ink dark:text-canvas-soft/90 font-light">
                    {t(`shared_finance.bullet${idx}`)}
                  </span>
                </li>
              ))}
            </ul>
          </div>

          {/* Right Visual Room Mockup Column - 6 cols */}
          <div className="lg:col-span-6">
            <div className="bg-canvas dark:bg-[#0d0e26] border border-hairline dark:border-hairline/10 rounded-[24px] p-6 shadow-level-2 transition-all duration-300 hover:shadow-xl">
              
              {/* Room Card Header */}
              <div className="flex justify-between items-center border-b border-hairline dark:border-hairline/10 pb-4 mb-6">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-[#f5e9d4] flex items-center justify-center border border-hairline/50">
                    <span className="text-xl">🏡</span>
                  </div>
                  <div>
                    <h3 className="font-bold text-sm text-ink dark:text-canvas">Living Room Expenses</h3>
                    <p className="text-xs text-ink-mute dark:text-canvas-soft/70">2 Members • Active</p>
                  </div>
                </div>
                <div className="flex -space-x-2">
                  <div className="w-8 h-8 rounded-full bg-primary/20 flex items-center justify-center text-xs font-bold border-2 border-white dark:border-[#0d0e26] text-primary">JD</div>
                  <div className="w-8 h-8 rounded-full bg-ruby/20 flex items-center justify-center text-xs font-bold border-2 border-white dark:border-[#0d0e26] text-ruby">AM</div>
                </div>
              </div>

              {/* Shared Budget Progress */}
              <div className="space-y-3 mb-6 bg-canvas-soft dark:bg-brand-dark-900/60 p-4 rounded-[16px] border border-hairline/30 dark:border-hairline/10">
                <div className="flex justify-between text-xs font-semibold">
                  <span className="text-ink dark:text-canvas-soft">Monthly Rent & Utility Budget</span>
                  <span className="text-primary-soft">Rp 1.250.000 / Rp 3.000.000</span>
                </div>
                <div className="w-full bg-hairline dark:bg-ink/50 h-2.5 rounded-full overflow-hidden">
                  <div className="bg-primary h-full rounded-full" style={{ width: '42%' }}></div>
                </div>
              </div>

              {/* Shared Ledger logs */}
              <div className="space-y-3">
                <div className="flex justify-between items-center p-3 hover:bg-canvas-soft dark:hover:bg-brand-dark-900 rounded-[12px] transition-colors">
                  <div className="flex items-center gap-3">
                    <ArrowRightLeft className="w-4 h-4 text-primary" />
                    <div>
                      <h4 className="font-semibold text-xs text-ink dark:text-canvas">Electricity Bill</h4>
                      <p className="text-[10px] text-ink-mute">Paid by John Doe</p>
                    </div>
                  </div>
                  <span className="text-xs font-semibold tnum text-ruby">- Rp 450.000</span>
                </div>

                <div className="flex justify-between items-center p-3 hover:bg-canvas-soft dark:hover:bg-brand-dark-900 rounded-[12px] transition-colors">
                  <div className="flex items-center gap-3">
                    <ArrowRightLeft className="w-4 h-4 text-primary" />
                    <div>
                      <h4 className="font-semibold text-xs text-ink dark:text-canvas">Internet Utilities</h4>
                      <p className="text-[10px] text-ink-mute">Paid by Alice Mary</p>
                    </div>
                  </div>
                  <span className="text-xs font-semibold tnum text-ruby">- Rp 350.000</span>
                </div>

                <div className="flex justify-between items-center p-3 hover:bg-canvas-soft dark:hover:bg-brand-dark-900 rounded-[12px] transition-colors">
                  <div className="flex items-center gap-3">
                    <UserCheck className="w-4 h-4 text-success" />
                    <div>
                      <h4 className="font-semibold text-xs text-ink dark:text-canvas">Weekly Room Sync</h4>
                      <p className="text-[10px] text-ink-mute">WebSocket System</p>
                    </div>
                  </div>
                  <span className="text-xs font-semibold text-primary dark:text-primary-soft">Synced</span>
                </div>
              </div>

            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
