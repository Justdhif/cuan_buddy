import { useTranslation } from 'react-i18next';
import { Sparkles, Terminal, MessageSquare, ArrowUpRight } from 'lucide-react';

export default function AIAssistant() {
  const { t } = useTranslation();

  return (
    <section className="py-24 bg-linear-canvas text-linear-ink border-b border-linear-hairline transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Left Text Column - Linear minimal layout (5-cols) */}
          <div className="lg:col-span-5 space-y-6">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded bg-[#10a37f]/10 border border-[#10a37f]/20 text-[#10a37f] text-[11px] font-semibold uppercase tracking-wider">
              <Sparkles size={12} />
              AI Intelligent Advisor
            </div>
            <h2 className="font-sans text-[36px] font-semibold tracking-tight leading-tight">
              {t('ai_assistant.title')}
            </h2>
            <p className="text-linear-ink-subtle text-[15px] leading-relaxed font-light">
              {t('ai_assistant.subtitle')}
            </p>
            <div className="pt-4 flex flex-col gap-3 text-[13px] text-linear-ink-muted">
              <div className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-[#10a37f]"></span>
                <span>Proactive saving recommendations</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-[#10a37f]"></span>
                <span>Natural language transaction search</span>
              </div>
            </div>
          </div>

          {/* Right AI Chat Console Column - OpenAI futuristic glow + Linear dense structure (7-cols) */}
          <div className="lg:col-span-7 relative">
            {/* OpenAI Green glow backdrop */}
            <div className="absolute inset-0 bg-[#10a37f]/5 rounded-[16px] blur-3xl -z-10"></div>
            
            {/* The Console Shell */}
            <div className="bg-[#0b0c0d] border border-linear-hairline rounded-[16px] overflow-hidden shadow-level-2 transition-all">
              {/* Console Header */}
              <div className="bg-linear-surface-1 px-5 py-3 border-b border-linear-hairline flex items-center justify-between">
                <div className="flex items-center gap-2 text-linear-ink/80 text-[12px] font-mono">
                  <Terminal size={14} className="text-[#10a37f]" />
                  <span>buddy-consultant-engine: v1.0.0</span>
                </div>
                <div className="w-2.5 h-2.5 rounded-full bg-[#10a37f] animate-pulse"></div>
              </div>

              {/* Chat Thread */}
              <div className="p-6 space-y-6 font-sans text-[14px]">
                {/* Message 1: User */}
                <div className="flex items-start gap-4">
                  <div className="w-8 h-8 rounded bg-linear-surface-2 border border-linear-hairline flex items-center justify-center text-linear-ink-subtle shrink-0">
                    <MessageSquare size={16} />
                  </div>
                  <div className="bg-linear-surface-1 border border-linear-hairline px-4 py-3 rounded-r-lg rounded-bl-lg max-w-[85%] font-light">
                    {t('ai_assistant.chat_q1')}
                  </div>
                </div>

                {/* Message 2: Buddy (OpenAI Glowing Green) */}
                <div className="flex items-start gap-4">
                  <div className="w-8 h-8 rounded bg-[#10a37f]/20 border border-[#10a37f]/30 flex items-center justify-center text-[#10a37f] shrink-0">
                    <Sparkles size={16} />
                  </div>
                  <div className="bg-[#10a37f]/5 border border-[#10a37f]/20 px-4 py-3 rounded-r-lg rounded-bl-lg max-w-[85%] font-light text-linear-ink">
                    <p>{t('ai_assistant.chat_a1')}</p>
                    <div className="flex items-center gap-1.5 mt-3 text-[11px] text-[#10a37f] font-semibold uppercase tracking-wider cursor-pointer hover:underline">
                      <span>View breakdown</span>
                      <ArrowUpRight size={12} />
                    </div>
                  </div>
                </div>

                {/* Message 3: User */}
                <div className="flex items-start gap-4">
                  <div className="w-8 h-8 rounded bg-linear-surface-2 border border-linear-hairline flex items-center justify-center text-linear-ink-subtle shrink-0">
                    <MessageSquare size={16} />
                  </div>
                  <div className="bg-linear-surface-1 border border-linear-hairline px-4 py-3 rounded-r-lg rounded-bl-lg max-w-[85%] font-light">
                    {t('ai_assistant.chat_q2')}
                  </div>
                </div>

                {/* Message 4: Buddy (OpenAI Glowing Green) */}
                <div className="flex items-start gap-4">
                  <div className="w-8 h-8 rounded bg-[#10a37f]/20 border border-[#10a37f]/30 flex items-center justify-center text-[#10a37f] shrink-0">
                    <Sparkles size={16} />
                  </div>
                  <div className="bg-[#10a37f]/5 border border-[#10a37f]/20 px-4 py-3 rounded-r-lg rounded-bl-lg max-w-[85%] font-light text-linear-ink">
                    <p>{t('ai_assistant.chat_a2')}</p>
                  </div>
                </div>
              </div>

              {/* Faux Input Bar */}
              <div className="p-4 border-t border-linear-hairline bg-[#090a0b] flex gap-2">
                <input 
                  type="text" 
                  placeholder="Ask Buddy anything..." 
                  disabled
                  className="bg-linear-surface-1 border border-linear-hairline text-linear-ink-subtle rounded-md px-3 py-2 text-[13px] flex-grow focus:outline-none"
                />
                <button className="bg-[#10a37f] text-white rounded-md px-3.5 py-2 text-[13px] font-medium opacity-80 cursor-not-allowed">
                  Send
                </button>
              </div>
            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
