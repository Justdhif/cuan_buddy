import { useTranslation } from 'react-i18next';
import { ArrowRight, Download } from 'lucide-react';

export default function DownloadCTA() {
  const { t } = useTranslation();

  return (
    <section id="download" className="py-24 bg-linear-canvas text-linear-ink border-b border-linear-hairline transition-colors duration-300">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        
        {/* Stripe + Linear style Banner Card Container */}
        <div className="relative rounded-[24px] bg-[#0c0d12] border border-linear-hairline p-10 md:p-16 overflow-hidden shadow-level-2 text-center flex flex-col items-center">
          
          {/* Stripe-style gradient mesh accent (placed inside card) */}
          <div className="absolute inset-0 opacity-20 pointer-events-none bg-[radial-gradient(circle_at_50%_0%,#5e6ad2_0%,transparent_60%),radial-gradient(circle_at_10%_90%,#ea2261_0%,transparent_50%)]"></div>

          <div className="relative z-10 max-w-2xl space-y-6">
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-linear-primary/10 border border-linear-primary/20 text-linear-primary-hover text-[11px] font-semibold tracking-wider uppercase mb-2">
              <Download size={12} />
              Instant Installation
            </div>
            
            <h2 className="font-sans text-[32px] sm:text-[42px] font-semibold tracking-tight text-linear-ink leading-tight">
              {t('download_cta.title')}
            </h2>
            
            <p className="text-linear-ink-subtle text-[15px] sm:text-[17px] leading-relaxed font-light">
              {t('download_cta.subtitle')}
            </p>

            <div className="pt-6 flex flex-wrap gap-4 items-center justify-center">
              <button className="inline-flex items-center justify-center gap-2 bg-linear-primary hover:bg-linear-primary-hover text-on-primary text-[14px] font-medium rounded-md px-5 py-2.5 shadow-level-1 transition-all duration-200 active:scale-95">
                Download for iOS
                <ArrowRight size={16} />
              </button>
              <button className="inline-flex items-center justify-center gap-2 bg-linear-surface-2 border border-linear-hairline hover:bg-linear-surface-3 text-linear-ink text-[14px] font-medium rounded-md px-5 py-2.5 shadow-level-1 transition-all duration-200 active:scale-95">
                Download for Android
                <Download size={16} />
              </button>
            </div>
          </div>
          
        </div>

      </div>
    </section>
  );
}
