import { useTranslation } from 'react-i18next';
import { Star, Shield, ThumbsUp, Users } from 'lucide-react';

export default function SocialProof() {
  const { t } = useTranslation();

  // Faux partners logo
  const partners = [
    { name: "Bank Central", icon: <Shield className="w-5 h-5 text-ink-mute/50 dark:text-linear-ink-subtle/50" /> },
    { name: "PayGlobal", icon: <ThumbsUp className="w-5 h-5 text-ink-mute/50 dark:text-linear-ink-subtle/50" /> },
    { name: "SecureFin", icon: <Users className="w-5 h-5 text-ink-mute/50 dark:text-linear-ink-subtle/50" /> },
    { name: "Alpha Capital", icon: <Shield className="w-5 h-5 text-ink-mute/50 dark:text-linear-ink-subtle/50" /> },
  ];

  return (
    <section className="py-12 bg-white dark:bg-linear-canvas border-b border-hairline/60 dark:border-linear-hairline transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col md:flex-row items-center justify-between gap-8">
          {/* Trust stats & ratings */}
          <div className="flex flex-col sm:flex-row items-center gap-6 text-center sm:text-left">
            <div className="flex -space-x-2">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="w-8 h-8 rounded-full bg-primary/10 border-2 border-white dark:border-linear-canvas flex items-center justify-center text-primary">
                  <Star size={12} fill="currentColor" className="text-primary dark:text-primary-soft" />
                </div>
              ))}
            </div>
            <div>
              <div className="text-[15px] font-semibold text-ink dark:text-linear-ink">{t('trusted.stats')}</div>
              <div className="text-[13px] text-ink-mute dark:text-linear-ink-subtle flex items-center justify-center sm:justify-start gap-1 mt-0.5">
                <span className="inline-block w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                {t('trusted.rating')}
              </div>
            </div>
          </div>

          {/* Marquee partners logos */}
          <div className="flex flex-wrap justify-center items-center gap-8 md:gap-12">
            {partners.map((partner, i) => (
              <div key={i} className="flex items-center gap-2 grayscale opacity-55 hover:opacity-85 hover:grayscale-0 transition-all duration-300">
                {partner.icon}
                <span className="font-semibold text-sm tracking-tight text-ink-mute dark:text-linear-ink-subtle">{partner.name}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
