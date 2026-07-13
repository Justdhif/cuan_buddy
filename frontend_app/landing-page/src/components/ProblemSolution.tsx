import { useTranslation } from 'react-i18next';
import { AlertCircle, CheckCircle, Sparkles } from 'lucide-react';

export default function ProblemSolution() {
  const { t } = useTranslation();

  return (
    <section className="py-24 bg-linear-canvas text-linear-ink border-y border-linear-hairline transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Linear display heading, weight 600, letter-spacing -1.8px */}
        <div className="text-center mb-16">
          <div className="text-[13px] font-semibold text-linear-primary tracking-widest uppercase mb-3">CONVERSATIONS</div>
          <h2 className="font-sans text-[36px] sm:text-[40px] font-semibold tracking-tight text-linear-ink max-w-2xl mx-auto leading-tight">
            {t('problem_solution.title')}
          </h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-5xl mx-auto">
          {/* The Problem Panel */}
          <div className="bg-linear-surface-1 border border-linear-hairline rounded-[12px] p-8 space-y-6">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded bg-red-950/40 border border-red-900/50 flex items-center justify-center text-red-400">
                <AlertCircle size={20} />
              </div>
              <h3 className="text-[20px] font-semibold text-linear-ink">{t('problem_solution.problem_title')}</h3>
            </div>
            
            <p className="text-linear-ink-muted/80 text-[15px] leading-relaxed font-light">
              {t('problem_solution.problem_desc')}
            </p>

            <div className="pt-4 border-t border-linear-hairline space-y-2 text-[13px] text-linear-ink-subtle">
              <div className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-red-500"></span>
                <span>Manual spreadsheet logging overhead</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-red-500"></span>
                <span>Uncoordinated joint/couple accounts</span>
              </div>
            </div>
          </div>

          {/* The Solution Panel (Highlighted with subtle lavender glow / primary border) */}
          <div className="bg-linear-surface-2 border border-linear-primary/30 rounded-[12px] p-8 space-y-6 relative overflow-hidden">
            {/* Subtle glow highlight */}
            <div className="absolute top-0 right-0 w-32 h-32 bg-linear-primary/10 rounded-full blur-3xl pointer-events-none"></div>

            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded bg-linear-primary/20 border border-linear-primary/40 flex items-center justify-center text-linear-primary-hover">
                <CheckCircle size={20} />
              </div>
              <h3 className="text-[20px] font-semibold text-linear-ink flex items-center gap-2">
                {t('problem_solution.solution_title')}
                <Sparkles size={16} className="text-linear-primary-hover animate-pulse" />
              </h3>
            </div>

            <p className="text-linear-ink-muted text-[15px] leading-relaxed font-light">
              {t('problem_solution.solution_desc')}
            </p>

            <div className="pt-4 border-t border-linear-hairline space-y-2 text-[13px] text-linear-primary-hover">
              <div className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-linear-primary"></span>
                <span>Instant automated categorization</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-linear-primary"></span>
                <span>Couples rooms synced over WebSockets</span>
              </div>
            </div>
          </div>
        </div>

      </div>
    </section>
  );
}
