import { useTranslation } from 'react-i18next';
import { Star, ShieldCheck, Users } from 'lucide-react';

export default function TrustedSection() {
  const { t } = useTranslation();

  return (
    <section className="py-12 bg-canvas dark:bg-ink border-y border-hairline/60 dark:border-hairline/10 transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 items-center text-center md:text-left">
          {/* Main Title/Proof */}
          <div className="md:col-span-1 flex flex-col justify-center">
            <h3 className="text-ink dark:text-canvas font-medium text-sm tracking-wider uppercase opacity-85 mb-1">
              Social Proof
            </h3>
            <p className="text-primary dark:text-primary-soft font-semibold text-lg">
              {t('trusted.stats')}
            </p>
          </div>

          {/* Stat Cards */}
          <div className="md:col-span-3 grid grid-cols-1 sm:grid-cols-3 gap-6">
            <div className="flex flex-col items-center p-4 bg-canvas-soft dark:bg-brand-dark-900 rounded-[12px] shadow-sm transition-all duration-300 hover:shadow-md">
              <Star className="w-8 h-8 text-lemon mb-2 animate-pulse" fill="#9b6829" />
              <span className="font-semibold text-lg text-ink dark:text-canvas">4.8 / 5.0</span>
              <span className="text-xs text-ink-mute dark:text-canvas-soft/75 mt-1">{t('trusted.rating')}</span>
            </div>

            <div className="flex flex-col items-center p-4 bg-canvas-soft dark:bg-brand-dark-900 rounded-[12px] shadow-sm transition-all duration-300 hover:shadow-md">
              <Users className="w-8 h-8 text-primary-soft mb-2" />
              <span className="font-semibold text-lg text-ink dark:text-canvas">50k+ Users</span>
              <span className="text-xs text-ink-mute dark:text-canvas-soft/75 mt-1">Active Smart Savers</span>
            </div>

            <div className="flex flex-col items-center p-4 bg-canvas-soft dark:bg-brand-dark-900 rounded-[12px] shadow-sm transition-all duration-300 hover:shadow-md">
              <ShieldCheck className="w-8 h-8 text-ruby mb-2" />
              <span className="font-semibold text-lg text-ink dark:text-canvas">100% Secured</span>
              <span className="text-xs text-ink-mute dark:text-canvas-soft/75 mt-1">Bank-Grade Encryption</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
