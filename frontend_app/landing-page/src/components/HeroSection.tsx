import { useTranslation } from 'react-i18next';
import { ArrowRight, Sparkles, TrendingUp, Wallet } from 'lucide-react';

export default function HeroSection() {
  const { t } = useTranslation();

  return (
    <section className="relative min-h-screen flex flex-col items-center justify-center pt-32 pb-24 overflow-hidden bg-canvas dark:bg-ink transition-colors duration-300">
      {/* Signature Gradient Mesh Backdrop */}
      <div className="gradient-mesh-backdrop opacity-70 dark:opacity-30"></div>

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center flex flex-col items-center">
        {/* Soft tag / Eyebrow */}
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary-bg-subdued-hover/40 border border-primary/20 text-primary-deep dark:text-primary-soft text-[11px] font-semibold tracking-wider uppercase mb-8 shadow-sm">
          <span className="flex h-1.5 w-1.5 rounded-full bg-primary animate-pulse"></span>
          CuanBuddy V1.0 is Live
        </div>
        
        {/* Hero Title - Display XXL, Weight 300, letter-spacing -1.4px */}
        <h1 className="font-display-xxl text-ink dark:text-canvas max-w-4xl mx-auto mb-6 leading-[1.05] text-4xl sm:text-5xl md:text-[64px]">
          {t('hero.title').split(' ').map((word: string, i: number) => (
            i === 0 
              ? <span key={i} className="text-primary dark:text-primary-soft font-normal">{word} </span> 
              : <span key={i}>{word} </span>
          ))}
        </h1>
        
        {/* Subtitle - Body LG, Weight 300 */}
        <p className="text-lg md:text-xl text-ink-secondary dark:text-canvas-soft/80 max-w-2xl mx-auto mb-10 leading-relaxed font-light">
          {t('hero.subtitle')}
        </p>

        {/* CTA Buttons */}
        <div className="flex flex-col sm:flex-row gap-4 items-center justify-center w-full sm:w-auto mb-20">
          <button className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-3 bg-primary hover:bg-primary-deep text-on-primary font-medium text-[15px] rounded-full shadow-level-1 transition-all active:bg-primary-press">
            {t('hero.cta')}
            <ArrowRight size={18} />
          </button>
          <a 
            href="#how" 
            className="w-full sm:w-auto flex items-center justify-center gap-2 px-6 py-3 bg-canvas dark:bg-brand-dark-900 border border-hairline dark:border-hairline/10 text-ink dark:text-canvas font-medium text-[15px] rounded-full hover:bg-canvas-soft dark:hover:bg-ink-secondary/50 shadow-level-1 transition-all"
          >
            {t('nav.howItWorks')}
          </a>
        </div>

        {/* Composited Dashboard Mockup (Dark-app polarity flip) */}
        <div className="w-full max-w-5xl rounded-[16px] bg-brand-dark-900 text-on-primary border border-hairline/10 shadow-level-2 overflow-hidden p-6 md:p-8 text-left transition-all duration-300">
          {/* Faux OS Window Bar */}
          <div className="flex justify-between items-center border-b border-hairline/10 pb-4 mb-6">
            <div className="flex gap-2">
              <span className="w-3 h-3 rounded-full bg-ruby/80"></span>
              <span className="w-3 h-3 rounded-full bg-lemon/80"></span>
              <span className="w-3 h-3 rounded-full bg-primary-soft/80"></span>
            </div>
            <div className="text-[12px] font-mono text-ink-mute tracking-wider uppercase">CuanBuddy OS v1.0.0</div>
            <div className="w-12"></div> {/* spacer */}
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            {/* Dashboard Sidebar - Left Panel (3-cols) */}
            <div className="lg:col-span-3 border-r border-hairline/10 pr-4 space-y-2 hidden md:block">
              <div className="text-[11px] font-semibold text-ink-mute uppercase tracking-widest px-2 mb-3">Workspace</div>
              <div className="flex items-center gap-2 px-3 py-2 bg-primary/10 border-l-2 border-primary text-primary-soft text-sm rounded-r-md">
                <Wallet size={16} />
                Overview
              </div>
              <div className="flex items-center gap-2 px-3 py-2 text-ink-mute hover:text-canvas text-sm transition-colors">
                <TrendingUp size={16} />
                Investments
              </div>
              <div className="flex items-center gap-2 px-3 py-2 text-ink-mute hover:text-canvas text-sm transition-colors">
                <Sparkles size={16} />
                AI Consultant
              </div>
            </div>

            {/* Main Mockup Area (9-cols) */}
            <div className="lg:col-span-9 space-y-6">
              {/* Cards Grid */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div className="bg-brand-dark-900/50 border border-hairline/10 rounded-[12px] p-4">
                  <div className="text-[12px] text-ink-mute mb-1">Total Balance</div>
                  <div className="text-xl font-medium tnum text-canvas">Rp 18.250.000</div>
                  <div className="text-[11px] text-primary-soft mt-1">▲ 12.3% this month</div>
                </div>
                
                <div className="bg-brand-dark-900/50 border border-hairline/10 rounded-[12px] p-4">
                  <div className="text-[12px] text-ink-mute mb-1">Monthly Budget</div>
                  <div className="text-xl font-medium tnum text-canvas">Rp 4.000.000</div>
                  <div className="text-[11px] text-lemon mt-1">Rp 1.450.000 remaining</div>
                </div>

                <div className="bg-brand-dark-900/50 border border-hairline/10 rounded-[12px] p-4">
                  <div className="text-[12px] text-ink-mute mb-1">AI Savings Goal</div>
                  <div className="text-xl font-medium tnum text-canvas">Rp 15.000.000</div>
                  <div className="text-[11px] text-ruby mt-1">72% Completed</div>
                </div>
              </div>

              {/* Console/Interactive Log & Chart */}
              <div className="bg-[#0f1035] border border-hairline/10 rounded-[12px] p-4 font-mono text-[13px] text-canvas-soft/90 space-y-3">
                <div className="flex items-center gap-2 border-b border-hairline/5 pb-2 text-[12px] text-ink-mute font-semibold">
                  <Sparkles size={14} className="text-primary-soft" />
                  CUANBUDDY AI INTELLIGENCE
                </div>
                <div className="text-primary-soft">&gt; analyzing financial statement: success</div>
                <div className="text-ink-mute">&gt; insight generated: "You saved Rp 450.000 by cooking at home instead of dining out. We recommend shifting this into your 'Emergency Fund' goal."</div>
                <div className="flex items-center gap-3 mt-4 pt-3 border-t border-hairline/5">
                  <span className="px-3 py-1 bg-primary/20 text-primary-soft rounded-full text-[11px] cursor-pointer hover:bg-primary/30 transition-all font-sans font-medium">Apply Recommendation</span>
                  <span className="text-ink-mute font-sans text-[11px]">Dismiss</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
