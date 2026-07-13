import { useTranslation } from 'react-i18next';
import { Users, Heart, MessageCircle, Sparkles } from 'lucide-react';

export default function SharedFinance() {
  const { t } = useTranslation();

  const bullets = [
    { text: t('shared_finance.bullet1'), icon: <Users className="w-5 h-5 text-airbnb-primary" /> },
    { text: t('shared_finance.bullet2'), icon: <Heart className="w-5 h-5 text-airbnb-primary" /> },
    { text: t('shared_finance.bullet3'), icon: <MessageCircle className="w-5 h-5 text-airbnb-primary" /> },
    { text: t('shared_finance.bullet4'), icon: <Sparkles className="w-5 h-5 text-airbnb-primary" /> }
  ];

  return (
    <section className="py-24 bg-white text-airbnb-ink transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Left Column: Airbnb style warm content (5-cols) */}
          <div className="lg:col-span-5 space-y-6 text-left">
            <span className="text-[12px] font-bold text-airbnb-primary uppercase tracking-widest block mb-2">SHARED FINANCE</span>
            <h2 className="font-sans text-[28px] sm:text-[32px] font-bold leading-tight tracking-tight text-airbnb-ink">
              {t('shared_finance.title')}
            </h2>
            <p className="text-[16px] text-airbnb-body leading-relaxed font-light">
              {t('shared_finance.subtitle')}
            </p>
            
            <ul className="space-y-4 pt-2">
              {bullets.map((bullet, i) => (
                <li key={i} className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-airbnb-primary/10 flex items-center justify-center shrink-0 mt-0.5">
                    {bullet.icon}
                  </div>
                  <span className="text-[15px] text-airbnb-body font-light leading-snug">{bullet.text}</span>
                </li>
              ))}
            </ul>
          </div>

          {/* Right Column: Airbnb style UI panel mockup with soft corners & warm tone (7-cols) */}
          <div className="lg:col-span-7 flex justify-center">
            <div className="w-full max-w-[480px] bg-white border border-airbnb-hairline rounded-[20px] shadow-airbnb-float p-6 relative overflow-hidden">
              <div className="flex items-center justify-between border-b border-airbnb-hairline pb-4 mb-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-pink-100 flex items-center justify-center text-airbnb-primary font-bold text-sm">
                    CB
                  </div>
                  <div>
                    <h4 className="font-semibold text-sm">Our Budget Room</h4>
                    <p className="text-[12px] text-airbnb-muted">Joint account active</p>
                  </div>
                </div>
                <span className="px-3 py-1 bg-airbnb-primary/10 text-airbnb-primary text-[11px] font-semibold rounded-full">
                  2 Members
                </span>
              </div>

              {/* Shared Activity list */}
              <div className="space-y-4 text-sm font-light">
                <div className="flex justify-between items-center bg-airbnb-surface-soft p-3 rounded-[14px]">
                  <div className="flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-airbnb-primary"></span>
                    <span>Andi added transaction</span>
                  </div>
                  <span className="font-medium tnum text-airbnb-ink">Rp 120.000</span>
                </div>

                <div className="flex justify-between items-center bg-airbnb-surface-soft p-3 rounded-[14px]">
                  <div className="flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-airbnb-primary"></span>
                    <span>Siti reacted with ❤️</span>
                  </div>
                  <span className="text-[12px] text-airbnb-muted">Just now</span>
                </div>
              </div>

              {/* Faux interactive invite box */}
              <div className="mt-6 pt-4 border-t border-airbnb-hairline flex items-center justify-between">
                <span className="text-[13px] text-airbnb-muted">Manage joint limit</span>
                <button className="bg-airbnb-primary hover:bg-airbnb-primary-active text-white text-[14px] font-semibold rounded-md px-4 py-2 transition-all">
                  Invite Member
                </button>
              </div>
            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
