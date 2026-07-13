import { useTranslation } from 'react-i18next';
import { ArrowRight, Sparkles, TrendingUp } from 'lucide-react';

export default function HeroSection() {
  const { t } = useTranslation();

  return (
    <section className="relative min-h-[90vh] flex flex-col items-center justify-center pt-40 pb-20 overflow-hidden bg-white dark:bg-linear-canvas transition-colors duration-300">
      {/* Stripe-inspired Organic Gradient Mesh Backdrop */}
      <div className="gradient-mesh-backdrop opacity-70 dark:opacity-20"></div>

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center flex flex-col items-center">
        {/* Apple-style eyebrow */}
        <div className="inline-flex items-center gap-1.5 text-[12px] font-semibold text-apple-primary dark:text-apple-primary-on-dark tracking-tight mb-6">
          <span>CuanBuddy V1.0 is Live</span>
          <ArrowRight size={12} />
        </div>
        
        {/* Apple-style centered headline */}
        <h1 className="font-sans text-apple-ink dark:text-linear-ink font-semibold tracking-tight text-4xl sm:text-5xl md:text-[56px] leading-[1.07] max-w-4xl mx-auto mb-6">
          {t('hero.title')}
        </h1>
        
        {/* Apple-style lead paragraph */}
        <p className="text-lg md:text-[21px] text-apple-ink/70 dark:text-linear-ink-muted/80 max-w-2xl mx-auto mb-10 leading-[1.4] font-normal tracking-wide">
          {t('hero.subtitle')}
        </p>

        {/* Apple Action Blue pill buttons */}
        <div className="flex flex-col sm:flex-row gap-4 items-center justify-center w-full sm:w-auto mb-24">
          <a 
            href="#download" 
            className="w-full sm:w-auto inline-flex items-center justify-center bg-apple-primary hover:bg-[#0071e3] text-white text-[17px] font-normal rounded-full px-6 py-3 shadow-sm hover:scale-[1.02] active:scale-95 transition-all duration-200"
          >
            {t('hero.cta')}
          </a>
          <a 
            href="#how" 
            className="w-full sm:w-auto inline-flex items-center justify-center text-apple-primary dark:text-apple-primary-on-dark hover:underline text-[17px] font-normal transition-all"
          >
            {t('nav.howItWorks')}
            <span className="ml-1">→</span>
          </a>
        </div>

        {/* Apple-style Device Mockup (with dark-mode support) */}
        <div className="relative w-full max-w-[850px] mx-auto rounded-[18px] bg-canvas dark:bg-linear-surface-1 border border-hairline dark:border-linear-hairline shadow-apple-product p-3 md:p-4 overflow-hidden transition-all duration-300">
          <div className="rounded-[12px] bg-[#f5f5f7] dark:bg-linear-surface-2 p-5 text-left text-apple-ink dark:text-linear-ink">
            {/* Faux OS Top Bar */}
            <div className="flex justify-between items-center mb-6 pb-2 border-b border-hairline dark:border-linear-hairline">
              <div className="flex gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-red-400"></span>
                <span className="w-2.5 h-2.5 rounded-full bg-yellow-400"></span>
                <span className="w-2.5 h-2.5 rounded-full bg-green-400"></span>
              </div>
              <div className="text-[12px] font-medium text-apple-ink/40 dark:text-linear-ink-subtle">cuanbuddy.com/dashboard</div>
              <div className="w-10"></div>
            </div>

            {/* Inner Dashboard Mockup Content */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="bg-white dark:bg-linear-surface-1 p-5 rounded-[11px] border border-hairline/80 dark:border-linear-hairline/80">
                <div className="text-[12px] text-apple-ink/50 dark:text-linear-ink-subtle font-medium mb-2 uppercase tracking-wider">Available Balance</div>
                <div className="text-2xl font-semibold tnum text-apple-ink dark:text-linear-ink">Rp 18.250.000</div>
                <div className="text-[12px] text-emerald-600 mt-2 flex items-center gap-1">
                  <TrendingUp size={14} /> +12.3% vs last month
                </div>
              </div>

              <div className="bg-white dark:bg-linear-surface-1 p-5 rounded-[11px] border border-hairline/80 dark:border-linear-hairline/80">
                <div className="text-[12px] text-apple-ink/50 dark:text-linear-ink-subtle font-medium mb-2 uppercase tracking-wider">Budget Status</div>
                <div className="text-2xl font-semibold tnum text-apple-ink dark:text-linear-ink">Rp 4.000.000</div>
                <div className="text-[12px] text-amber-600 mt-2">Rp 1.450.000 remaining</div>
              </div>

              <div className="bg-white dark:bg-linear-surface-1 p-5 rounded-[11px] border border-hairline/80 dark:border-linear-hairline/80">
                <div className="text-[12px] text-apple-ink/50 dark:text-linear-ink-subtle font-medium mb-2 uppercase tracking-wider">AI Consultant Advisor</div>
                <div className="text-2xl font-semibold text-apple-primary dark:text-apple-primary-on-dark flex items-center gap-1.5">
                  <Sparkles size={20} className="animate-pulse" />
                  Active
                </div>
                <div className="text-[12px] text-apple-ink/65 dark:text-linear-ink-muted/80 mt-2">Buddy generated 3 alerts</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
export {};
