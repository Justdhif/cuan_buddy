import { useTranslation } from 'react-i18next';
import { XCircle, CheckCircle2, TrendingUp, AlertTriangle } from 'lucide-react';

export default function ProblemSolutionSection() {
  const { t } = useTranslation();

  return (
    <section className="py-24 bg-canvas-soft dark:bg-brand-dark-900/40 border-b border-hairline/60 dark:border-hairline/10 transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="font-display-xl text-ink dark:text-canvas mb-4 text-3xl sm:text-4xl text-center">
            {t('problem_solution.title')}
          </h2>
          <div className="w-16 h-1 bg-primary dark:bg-primary-soft mx-auto rounded-full"></div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-stretch">
          {/* Problem Card */}
          <div className="bg-canvas dark:bg-brand-dark-900 border border-ruby/20 dark:border-ruby/10 rounded-[20px] p-8 md:p-10 flex flex-col justify-between shadow-sm relative overflow-hidden transition-all duration-300 hover:shadow-lg">
            <div className="absolute top-0 right-0 w-24 h-24 bg-ruby/5 dark:bg-ruby/2 rounded-full filter blur-xl"></div>
            <div>
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-ruby/10 text-ruby text-xs font-semibold uppercase tracking-wider mb-6">
                <AlertTriangle size={14} />
                {t('problem_solution.problem_title')}
              </div>
              <p className="text-lg md:text-xl text-ink dark:text-canvas mb-8 leading-relaxed font-light">
                {t('problem_solution.problem_desc')}
              </p>
              
              <ul className="space-y-4">
                <li className="flex items-start gap-3">
                  <XCircle className="w-5 h-5 text-ruby shrink-0 mt-0.5" />
                  <span className="text-[15px] text-ink-mute dark:text-canvas-soft/80 font-light">Losing track of micro-spending and subscription fees.</span>
                </li>
                <li className="flex items-start gap-3">
                  <XCircle className="w-5 h-5 text-ruby shrink-0 mt-0.5" />
                  <span className="text-[15px] text-ink-mute dark:text-canvas-soft/80 font-light">Overspending consistently without realizing until it is too late.</span>
                </li>
                <li className="flex items-start gap-3">
                  <XCircle className="w-5 h-5 text-ruby shrink-0 mt-0.5" />
                  <span className="text-[15px] text-ink-mute dark:text-canvas-soft/80 font-light">Struggling to align monthly expenses with partners or flatmates.</span>
                </li>
              </ul>
            </div>
          </div>

          {/* Solution Card - Polarity flip with electric indigo styling */}
          <div className="bg-gradient-to-br from-primary to-primary-deep text-on-primary rounded-[20px] p-8 md:p-10 flex flex-col justify-between shadow-level-2 relative overflow-hidden transition-all duration-300 hover:shadow-xl">
            <div className="absolute -bottom-10 -right-10 w-40 h-40 bg-white/10 rounded-full filter blur-2xl"></div>
            <div>
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/20 text-white text-xs font-semibold uppercase tracking-wider mb-6">
                <TrendingUp size={14} />
                {t('problem_solution.solution_title')}
              </div>
              <p className="text-lg md:text-xl text-white mb-8 leading-relaxed font-light">
                {t('problem_solution.solution_desc')}
              </p>
              
              <ul className="space-y-4 text-white/90">
                <li className="flex items-start gap-3">
                  <CheckCircle2 className="w-5 h-5 text-white shrink-0 mt-0.5 animate-pulse" />
                  <span className="text-[15px] font-light">Instant single-tap logging & automatic transaction records.</span>
                </li>
                <li className="flex items-start gap-3">
                  <CheckCircle2 className="w-5 h-5 text-white shrink-0 mt-0.5 animate-pulse" />
                  <span className="text-[15px] font-light">Predictive AI-driven budget alerts to guard your savings.</span>
                </li>
                <li className="flex items-start gap-3">
                  <CheckCircle2 className="w-5 h-5 text-white shrink-0 mt-0.5 animate-pulse" />
                  <span className="text-[15px] font-light">Shared room synchronization for dual or group account alignment.</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
