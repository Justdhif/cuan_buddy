import { useTranslation } from 'react-i18next';
import { ShieldCheck, Database, KeyRound, EyeOff } from 'lucide-react';

export default function SecurityPrivacySection() {
  const { t } = useTranslation();

  const securityItems = [
    {
      icon: <KeyRound className="w-6 h-6 text-primary dark:text-primary-soft" />,
      title: t('security.f1_title'),
      desc: t('security.f1_desc')
    },
    {
      icon: <Database className="w-6 h-6 text-lemon" />,
      title: t('security.f2_title'),
      desc: t('security.f2_desc')
    },
    {
      icon: <EyeOff className="w-6 h-6 text-ruby" />,
      title: t('security.f3_title'),
      desc: t('security.f3_desc')
    }
  ];

  return (
    <section className="py-24 bg-canvas dark:bg-[#0c0d24] transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Mock Shield Graphic - Left Column (5 cols) */}
          <div className="lg:col-span-5 order-last lg:order-first flex justify-center relative">
            <div className="absolute w-72 h-72 bg-primary/10 rounded-full filter blur-3xl animate-pulse"></div>
            <div className="relative bg-brand-dark-900 border border-hairline/10 rounded-[32px] p-10 shadow-level-2 text-center max-w-sm flex flex-col items-center">
              <div className="w-20 h-20 rounded-full bg-primary/10 flex items-center justify-center mb-6">
                <ShieldCheck className="w-10 h-10 text-primary-soft" />
              </div>
              <h3 className="text-xl font-bold text-white mb-2">SECURE SHELL</h3>
              <p className="text-xs text-ink-mute leading-relaxed font-mono">
                AES-256-GCM KEY EXCHANGE<br/>
                AUTHENTICATED ENCRYPTION<br/>
                STATUS: PROTECTED
              </p>
            </div>
          </div>

          {/* Text and Features Grid - Right Column (7 cols) */}
          <div className="lg:col-span-7 space-y-8">
            <div className="space-y-4">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-ruby/10 border border-ruby/20 text-ruby text-[11px] font-semibold tracking-wider uppercase">
                <ShieldCheck size={12} />
                Strict Privacy Protocols
              </div>
              <h2 className="font-display-xl text-ink dark:text-canvas text-3xl sm:text-4xl leading-tight">
                {t('security.title')}
              </h2>
              <p className="text-[16px] text-ink-secondary dark:text-canvas-soft/80 leading-relaxed font-light">
                {t('security.subtitle')}
              </p>
            </div>

            <div className="space-y-6">
              {securityItems.map((item, idx) => (
                <div key={idx} className="flex gap-4">
                  <div className="w-12 h-12 rounded-full bg-canvas-soft dark:bg-brand-dark-900 flex items-center justify-center shrink-0 border border-hairline dark:border-hairline/10">
                    {item.icon}
                  </div>
                  <div>
                    <h4 className="font-semibold text-[16px] text-ink dark:text-canvas">{item.title}</h4>
                    <p className="text-[14px] text-ink-mute dark:text-canvas-soft/75 mt-1 font-light leading-relaxed">
                      {item.desc}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
