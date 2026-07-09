import { useTranslation } from 'react-i18next';
import { Wallet, TrendingUp, Sparkles } from 'lucide-react';

export default function FeaturesSection() {
  const { t } = useTranslation();

  const features = [
    {
      icon: <Wallet className="w-8 h-8 text-primary" />,
      title: t('features.f1_title'),
      desc: t('features.f1_desc'),
      bg: 'bg-primary/10',
      borderColor: 'hover:border-primary/50'
    },
    {
      icon: <TrendingUp className="w-8 h-8 text-secondary" />,
      title: t('features.f2_title'),
      desc: t('features.f2_desc'),
      bg: 'bg-secondary/10',
      borderColor: 'hover:border-secondary/50'
    },
    {
      icon: <Sparkles className="w-8 h-8 text-accent" />,
      title: t('features.f3_title'),
      desc: t('features.f3_desc'),
      bg: 'bg-accent/10',
      borderColor: 'hover:border-accent/50'
    }
  ];

  return (
    <section id="features" className="py-24 bg-background">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-extrabold mb-4">{t('features.title')}</h2>
          <div className="w-24 h-1.5 bg-gradient-to-r from-primary to-accent mx-auto rounded-full"></div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {features.map((feature, i) => (
            <div key={i} className={`group p-8 rounded-3xl bg-card border border-border shadow-sm hover:shadow-xl ${feature.borderColor} transition-all duration-300`}>
              <div className={`w-16 h-16 rounded-2xl ${feature.bg} flex items-center justify-center mb-6 group-hover:scale-110 group-hover:rotate-3 transition-transform duration-300`}>
                {feature.icon}
              </div>
              <h3 className="text-2xl font-bold mb-3">{feature.title}</h3>
              <p className="text-foreground/70 leading-relaxed font-medium">
                {feature.desc}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
