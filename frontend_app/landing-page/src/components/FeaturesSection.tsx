import { useTranslation } from 'react-i18next';
import { Wallet, TrendingUp, Sparkles } from 'lucide-react';

export default function FeaturesSection() {
  const { t } = useTranslation();

  const features = [
    {
      icon: <Wallet className="w-6 h-6 text-primary dark:text-primary-soft" />,
      title: t('features.f1_title'),
      desc: t('features.f1_desc'),
      type: 'light' // card-feature-light
    },
    {
      icon: <TrendingUp className="w-6 h-6 text-[#9b6829]" />,
      title: t('features.f2_title'),
      desc: t('features.f2_desc'),
      type: 'cream' // card-cream-band (warm interlude)
    },
    {
      icon: <Sparkles className="w-6 h-6 text-primary dark:text-primary-soft" />,
      title: t('features.f3_title'),
      desc: t('features.f3_desc'),
      type: 'light' // card-feature-light
    }
  ];

  return (
    <section id="features" className="py-24 bg-canvas-soft dark:bg-[#0f1025] transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          {/* display-xl heading, weight 300, negative tracking */}
          <h2 className="font-display-xl text-ink dark:text-canvas mb-4 text-3xl sm:text-4xl">
            {t('features.title')}
          </h2>
          <div className="w-16 h-1 bg-primary dark:bg-primary-soft mx-auto rounded-full"></div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {features.map((feature, i) => {
            if (feature.type === 'cream') {
              return (
                <div 
                  key={i} 
                  className="card-cream-band bg-canvas-cream text-ink p-8 rounded-[12px] shadow-level-1 hover:shadow-level-2 transition-all duration-300 hover:-translate-y-1 flex flex-col justify-between"
                >
                  <div>
                    <div className="w-12 h-12 rounded-full bg-white/60 flex items-center justify-center mb-6">
                      {feature.icon}
                    </div>
                    <h3 className="font-display-md text-ink mb-3 text-[22px] sm:text-2xl">{feature.title}</h3>
                    <p className="text-ink-secondary leading-relaxed font-light text-[15px]">
                      {feature.desc}
                    </p>
                  </div>
                </div>
              );
            }

            return (
              <div 
                key={i} 
                className="card-feature-light bg-canvas dark:bg-brand-dark-900 text-ink dark:text-canvas p-8 rounded-[12px] border border-hairline dark:border-hairline/10 shadow-level-1 hover:shadow-level-2 transition-all duration-300 hover:-translate-y-1 flex flex-col justify-between"
              >
                <div>
                  <div className="w-12 h-12 rounded-full bg-canvas-soft dark:bg-ink/50 flex items-center justify-center mb-6">
                    {feature.icon}
                  </div>
                  <h3 className="font-display-md text-ink dark:text-canvas mb-3 text-[22px] sm:text-2xl">{feature.title}</h3>
                  <p className="text-ink-mute dark:text-canvas-soft/80 leading-relaxed font-light text-[15px]">
                    {feature.desc}
                  </p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
