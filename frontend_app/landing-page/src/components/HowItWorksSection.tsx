import { useTranslation } from 'react-i18next';
import { Download, Target, PiggyBank } from 'lucide-react';

export default function HowItWorksSection() {
  const { t } = useTranslation();

  const steps = [
    { num: "01", title: t('how.step1'), desc: "Install CuanBuddy on your iOS or Android device securely.", icon: <Download size={20} className="text-primary" /> },
    { num: "02", title: t('how.step2'), desc: "Input savings milestones and set custom limits.", icon: <Target size={20} className="text-primary" /> },
    { num: "03", title: t('how.step3'), desc: "Save effortlessly as AI assists your budget management.", icon: <PiggyBank size={20} className="text-primary" /> }
  ];

  return (
    <section id="how" className="py-24 bg-white transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <span className="text-[13px] font-semibold text-primary uppercase tracking-widest block mb-3">WORKFLOW</span>
          <h2 className="text-3xl md:text-[38px] font-extrabold text-ink tracking-tight mb-4">{t('how.title')}</h2>
          <div className="w-12 h-1 bg-primary mx-auto rounded-full"></div>
        </div>

        <div className="relative pt-10">
          {/* Stripe-style horizontal connector line (desktop only) */}
          <div className="hidden md:block absolute top-[44px] left-[10%] right-[10%] h-[1px] bg-hairline"></div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-12 max-w-5xl mx-auto">
            {steps.map((step, i) => (
              <div key={i} className="flex flex-col items-center text-center group relative bg-white">
                <div className="w-12 h-12 rounded-full bg-[#f6f9fc] border border-hairline flex items-center justify-center mb-6 group-hover:border-primary group-hover:scale-105 transition-all duration-300 relative z-10">
                  {step.icon}
                </div>
                <div className="text-primary font-bold text-[13px] tracking-wider uppercase mb-2 tnum">Step {step.num}</div>
                <h3 className="text-[18px] font-bold text-ink mb-2">{step.title}</h3>
                <p className="text-[14px] text-ink-mute max-w-[250px] leading-relaxed font-light">{step.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
