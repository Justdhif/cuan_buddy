import { useTranslation } from 'react-i18next';
import { Download, AppWindow } from 'lucide-react';

export default function DownloadCtaSection() {
  const { t } = useTranslation();

  return (
    <section id="download" className="py-24 bg-canvas dark:bg-[#0c0d24] transition-colors duration-300">
      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-gradient-to-br from-primary to-primary-deep text-on-primary rounded-[32px] p-8 md:p-16 text-center relative overflow-hidden shadow-level-2">
          {/* Decorative shapes */}
          <div className="absolute top-0 left-0 w-64 h-64 bg-white/5 rounded-full filter blur-3xl"></div>
          <div className="absolute bottom-0 right-0 w-64 h-64 bg-magenta/10 rounded-full filter blur-3xl"></div>

          <div className="relative z-10 max-w-3xl mx-auto flex flex-col items-center">
            <h2 className="font-display-xl text-white mb-6 text-3xl sm:text-4xl md:text-5xl leading-tight">
              {t('download_cta.title')}
            </h2>
            <p className="text-lg text-white/90 mb-10 leading-relaxed font-light">
              {t('download_cta.subtitle')}
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center w-full sm:w-auto">
              {/* App Store Button */}
              <a 
                href="#"
                className="w-full sm:w-auto flex items-center justify-center gap-3 bg-white text-ink hover:bg-canvas-cream font-medium px-8 py-3.5 rounded-full shadow-md transition-all active:scale-95 duration-200"
              >
                <AppWindow className="w-5 h-5 text-primary" />
                <div className="text-left leading-none">
                  <span className="text-[10px] block opacity-80 font-light">Download on the</span>
                  <span className="text-sm font-bold block mt-0.5">App Store</span>
                </div>
              </a>

              {/* Play Store Button */}
              <a 
                href="#"
                className="w-full sm:w-auto flex items-center justify-center gap-3 bg-brand-dark-900 text-white hover:bg-brand-dark-900/90 font-medium px-8 py-3.5 rounded-full shadow-md transition-all active:scale-95 duration-200 border border-hairline/10"
              >
                <Download className="w-5 h-5 text-primary-soft" />
                <div className="text-left leading-none">
                  <span className="text-[10px] block opacity-80 font-light">Get it on</span>
                  <span className="text-sm font-bold block mt-0.5">Google Play</span>
                </div>
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
