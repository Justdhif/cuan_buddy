import { useTranslation } from 'react-i18next';
import { Wallet, TrendingUp, Sparkles } from 'lucide-react';

export default function FeaturesSection() {
  const { t } = useTranslation();

  const features = [
    {
      icon: <Wallet className="w-5 h-5 text-linear-primary-hover" />,
      title: t('features.f1_title'),
      desc: t('features.f1_desc')
    },
    {
      icon: <TrendingUp className="w-5 h-5 text-linear-primary-hover" />,
      title: t('features.f2_title'),
      desc: t('features.f2_desc')
    },
    {
      icon: <Sparkles className="w-5 h-5 text-linear-primary-hover" />,
      title: t('features.f3_title'),
      desc: t('features.f3_desc')
    }
  ];

  return (
    <section id="features" className="py-24 bg-linear-canvas border-b border-linear-hairline transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-20">
          <div className="text-[13px] font-semibold text-linear-primary tracking-widest uppercase mb-3">PRODUCT DETAILS</div>
          <h2 className="font-sans text-[36px] sm:text-[40px] font-semibold tracking-tight text-linear-ink mb-4">
            {t('features.title')}
          </h2>
          <div className="w-12 h-[2px] bg-linear-primary mx-auto rounded-full"></div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {features.map((feature, i) => (
            <div 
              key={i} 
              className="bg-linear-surface-1 border border-linear-hairline rounded-[12px] p-8 shadow-level-1 hover:border-linear-primary/40 transition-all duration-300 flex flex-col justify-between"
            >
              <div>
                <div className="w-10 h-10 rounded-md bg-linear-surface-2 border border-linear-hairline flex items-center justify-center mb-6">
                  {feature.icon}
                </div>
                <h3 className="font-sans text-[18px] font-medium text-linear-ink mb-3">{feature.title}</h3>
                <p className="text-linear-ink-subtle leading-relaxed font-light text-[14px]">
                  {feature.desc}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
