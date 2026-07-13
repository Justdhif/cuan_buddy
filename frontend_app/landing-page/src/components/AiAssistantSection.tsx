import { useTranslation } from 'react-i18next';
import { Sparkles, Compass, Shield } from 'lucide-react';

export default function AiAssistantSection() {
  const { t } = useTranslation();

  return (
    <section className="py-24 bg-canvas dark:bg-[#0d0e26] overflow-hidden transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Left Text Column - 5 cols */}
          <div className="lg:col-span-5 space-y-6">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary-bg-subdued-hover/40 border border-primary/20 text-primary-deep dark:text-primary-soft text-[11px] font-semibold tracking-wider uppercase">
              <Sparkles size={12} className="animate-spin" />
              AI-Powered Companion
            </div>
            
            <h2 className="font-display-xl text-ink dark:text-canvas text-3xl sm:text-4xl leading-tight">
              {t('ai_assistant.title')}
            </h2>
            
            <p className="text-[16px] text-ink-secondary dark:text-canvas-soft/80 leading-relaxed font-light">
              {t('ai_assistant.subtitle')}
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 pt-4">
              <div className="flex gap-3">
                <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                  <Compass className="w-5 h-5 text-primary-soft" />
                </div>
                <div>
                  <h4 className="font-semibold text-ink dark:text-canvas text-sm">Smart Advice</h4>
                  <p className="text-xs text-ink-mute dark:text-canvas-soft/75 mt-1 font-light">Weekly goal tips & spending pattern summaries.</p>
                </div>
              </div>
              
              <div className="flex gap-3">
                <div className="w-10 h-10 rounded-full bg-ruby/10 flex items-center justify-center shrink-0">
                  <Shield className="w-5 h-5 text-ruby" />
                </div>
                <div>
                  <h4 className="font-semibold text-ink dark:text-canvas text-sm">Safe & Private</h4>
                  <p className="text-xs text-ink-mute dark:text-canvas-soft/75 mt-1 font-light">Local-first privacy model for transactions.</p>
                </div>
              </div>
            </div>
          </div>

          {/* Right Mockup Column - 7 cols */}
          <div className="lg:col-span-7 relative">
            {/* Background Mesh Glow */}
            <div className="absolute -top-12 -left-12 w-64 h-64 bg-primary/10 dark:bg-primary/5 rounded-full filter blur-3xl"></div>
            <div className="absolute -bottom-12 -right-12 w-64 h-64 bg-magenta/10 dark:bg-magenta/5 rounded-full filter blur-3xl"></div>

            <div className="relative bg-brand-dark-900 border border-hairline/10 rounded-[20px] p-6 shadow-level-2 text-on-primary">
              
              {/* Header */}
              <div className="flex items-center gap-3 border-b border-hairline/10 pb-4 mb-4">
                <div className="w-8 h-8 rounded-full bg-primary flex items-center justify-center">
                  <Sparkles size={16} className="text-white animate-pulse" />
                </div>
                <div>
                  <h3 className="font-semibold text-sm">Buddy</h3>
                  <span className="text-[10px] text-primary-soft uppercase font-mono tracking-wider">Online • Financial Consultant</span>
                </div>
              </div>

              {/* Chat Log */}
              <div className="space-y-4 font-sans text-sm">
                
                {/* Q1 */}
                <div className="flex justify-end">
                  <div className="bg-primary/20 border border-primary-soft/30 rounded-t-[14px] rounded-bl-[14px] p-3 max-w-[85%]">
                    <p className="text-white font-light text-[13px]">{t('ai_assistant.chat_q1')}</p>
                  </div>
                </div>

                {/* A1 */}
                <div className="flex justify-start gap-2">
                  <div className="w-6 h-6 rounded-full bg-primary flex items-center justify-center shrink-0 mt-1">
                    <Sparkles size={12} className="text-white" />
                  </div>
                  <div className="bg-[#0f1035] border border-hairline/10 rounded-t-[14px] rounded-br-[14px] p-3 max-w-[85%]">
                    <p className="text-canvas-soft/90 font-light text-[13px]">{t('ai_assistant.chat_a1')}</p>
                  </div>
                </div>

                {/* Q2 */}
                <div className="flex justify-end">
                  <div className="bg-primary/20 border border-primary-soft/30 rounded-t-[14px] rounded-bl-[14px] p-3 max-w-[85%]">
                    <p className="text-white font-light text-[13px]">{t('ai_assistant.chat_q2')}</p>
                  </div>
                </div>

                {/* A2 */}
                <div className="flex justify-start gap-2">
                  <div className="w-6 h-6 rounded-full bg-primary flex items-center justify-center shrink-0 mt-1">
                    <Sparkles size={12} className="text-white" />
                  </div>
                  <div className="bg-[#0f1035] border border-hairline/10 rounded-t-[14px] rounded-br-[14px] p-3 max-w-[85%]">
                    <p className="text-canvas-soft/90 font-light text-[13px]">{t('ai_assistant.chat_a2')}</p>
                  </div>
                </div>

              </div>
            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
