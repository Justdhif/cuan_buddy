import { useTranslation } from 'react-i18next';
import { Shield, Key, EyeOff } from 'lucide-react';

export default function SecurityPrivacy() {
  const { t } = useTranslation();

  const securityFeatures = [
    {
      icon: <Shield className="w-6 h-6 text-primary" />,
      title: t('security.f1_title'),
      desc: t('security.f1_desc')
    },
    {
      icon: <Key className="w-6 h-6 text-primary" />,
      title: t('security.f2_title'),
      desc: t('security.f2_desc')
    },
    {
      icon: <EyeOff className="w-6 h-6 text-primary" />,
      title: t('security.f3_title'),
      desc: t('security.f3_desc')
    }
  ];

  return (
    <section className="py-24 bg-[#f6f9fc] border-b border-hairline/60 transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Stripe Header */}
        <div className="text-center mb-20 max-w-3xl mx-auto">
          <span className="text-[13px] font-semibold text-primary uppercase tracking-widest block mb-3">TRUST & INFRASTRUCTURE</span>
          <h2 className="text-3xl md:text-[38px] font-extrabold text-ink tracking-tight mb-4">{t('security.title')}</h2>
          <p className="text-lg text-ink-mute leading-relaxed font-light">{t('security.subtitle')}</p>
        </div>

        {/* Stripe-style High-Trust Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {securityFeatures.map((feat, i) => (
            <div key={i} className="bg-white border border-hairline rounded-[12px] p-8 shadow-level-1 hover:shadow-level-2 transition-all duration-300">
              <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center mb-6">
                {feat.icon}
              </div>
              <h3 className="text-[18px] font-bold text-ink mb-3">{feat.title}</h3>
              <p className="text-[14px] text-ink-mute leading-relaxed font-light">{feat.desc}</p>
            </div>
          ))}
        </div>

      </div>
    </section>
  );
}
