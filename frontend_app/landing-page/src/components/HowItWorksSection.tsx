import { useTranslation } from 'react-i18next';
import { Download, Target, PiggyBank } from 'lucide-react';

export default function HowItWorksSection() {
  const { t } = useTranslation();

  const steps = [
    { num: "01", title: t('how.step1'), icon: <Download size={20} className="text-primary dark:text-primary-soft" /> },
    { num: "02", title: t('how.step2'), icon: <Target size={20} className="text-primary dark:text-primary-soft" /> },
    { num: "03", title: t('how.step3'), icon: <PiggyBank size={20} className="text-primary dark:text-primary-soft" /> }
  ];

  return (
    <section id="how" className="py-24 bg-canvas dark:bg-ink border-y border-hairline/60 dark:border-hairline/10 transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-20">
          <h2 className="font-display-xl text-ink dark:text-canvas mb-4 text-3xl sm:text-4xl">{t('how.title')}</h2>
          <div className="w-16 h-1 bg-primary dark:bg-primary-soft mx-auto rounded-full"></div>
        </div>

        <div className="relative">
          {/* Connector Line (hidden on mobile, shown on desktop) */}
          <div className="hidden md:block absolute top-[44px] left-[15%] right-[15%] h-[1px] bg-hairline dark:bg-hairline/10 -z-10"></div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-12 max-w-5xl mx-auto">
            {steps.map((step, i) => (
              <div key={i} className="flex flex-col items-center text-center group">
                <div className="w-[88px] h-[88px] rounded-full bg-canvas dark:bg-brand-dark-900 border border-hairline dark:border-hairline/10 shadow-level-1 flex items-center justify-center mb-6 group-hover:border-primary dark:group-hover:border-primary-soft transition-all duration-300">
                  {step.icon}
                </div>
                <div className="text-[12px] font-semibold text-primary dark:text-primary-soft tracking-widest uppercase mb-2 tnum">Step {step.num}</div>
                <h3 className="font-heading-md text-ink dark:text-canvas max-w-[200px] leading-snug">{step.title}</h3>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
