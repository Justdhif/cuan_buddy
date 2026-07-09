import { useTranslation } from 'react-i18next';
import { Download, Target, PiggyBank } from 'lucide-react';

export default function HowItWorksSection() {
  const { t } = useTranslation();

  const steps = [
    { num: "01", title: t('how.step1'), icon: <Download size={24} /> },
    { num: "02", title: t('how.step2'), icon: <Target size={24} /> },
    { num: "03", title: t('how.step3'), icon: <PiggyBank size={24} /> }
  ];

  return (
    <section id="how" className="py-24 bg-card border-y border-border/50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-extrabold mb-4">{t('how.title')}</h2>
          <div className="w-24 h-1.5 bg-gradient-to-r from-secondary to-primary mx-auto rounded-full"></div>
        </div>

        <div className="relative pt-10">
          {/* Connector Line */}
          <div className="hidden md:block absolute top-20 left-16 right-16 h-1 bg-border rounded-full -z-10"></div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
            {steps.map((step, i) => (
              <div key={i} className="flex flex-col items-center text-center group">
                <div className="w-20 h-20 rounded-full bg-background shadow-xl border-4 border-border flex items-center justify-center mb-6 group-hover:border-primary group-hover:scale-110 transition-all duration-300">
                  <span className="text-foreground group-hover:text-primary transition-colors">{step.icon}</span>
                </div>
                <div className="text-primary font-bold text-xl mb-2">{step.num}</div>
                <h3 className="text-2xl font-bold">{step.title}</h3>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
