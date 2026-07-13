import { useTranslation } from 'react-i18next';
import { ChevronRight } from 'lucide-react';

export default function AppShowcase() {
  const { t } = useTranslation();

  return (
    <section className="bg-white text-apple-ink transition-colors duration-300">
      
      {/* Title Header Section - Always Light */}
      <div className="py-16 text-center max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <h2 className="font-sans text-apple-ink font-semibold tracking-tight text-3xl sm:text-4xl md:text-[40px] leading-tight mb-2">
          {t('screenshots.title')}
        </h2>
      </div>

      {/* Tile 1: Dashboard Overview (Apple Light Tile style) */}
      <div className="bg-white py-16 border-b border-hairline/60 overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          <div className="lg:col-span-5 space-y-4 text-left">
            <span className="text-[12px] font-semibold text-apple-primary tracking-widest uppercase">TRACKING</span>
            <h3 className="font-sans text-apple-ink font-semibold text-[32px] sm:text-[40px] leading-tight tracking-tight">
              {t('screenshots.screen1')}
            </h3>
            <p className="text-[17px] text-apple-ink/70 leading-relaxed font-light">
              See your entire financial picture in one place. Expenses, balances, and AI warnings compiled into a beautiful feed.
            </p>
            <div className="pt-2">
              <a href="#features" className="inline-flex items-center text-apple-primary hover:underline text-[17px] font-normal gap-0.5">
                Learn more about tracking <ChevronRight size={16} />
              </a>
            </div>
          </div>
          
          {/* Mock Mobile App screen using image */}
          <div className="lg:col-span-7 flex justify-center">
            <div className="w-[300px] h-[550px] rounded-[32px] bg-apple-ink border-[8px] border-apple-ink shadow-apple-product overflow-hidden relative">
              <img 
                src="/app_screen_mockup.png" 
                alt="Dashboard Screen Mockup" 
                className="w-full h-full object-cover rounded-[24px]"
                onError={(e) => { e.currentTarget.src = "/app_icon_transparent.png"; }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Tile 2: Budget Monitor (Apple Parchment Tile style) */}
      <div className="bg-apple-canvas-parchment py-16 border-b border-hairline/60 overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          {/* Mock Mobile App screen using image */}
          <div className="lg:col-span-7 flex justify-center order-2 lg:order-1">
            <div className="w-[300px] h-[550px] rounded-[32px] bg-apple-ink border-[8px] border-apple-ink shadow-apple-product overflow-hidden relative">
              <img 
                src="/app_screen_mockup.png" 
                alt="Budget Screen Mockup" 
                className="w-full h-full object-cover rounded-[24px]"
                onError={(e) => { e.currentTarget.src = "/app_icon_transparent.png"; }}
              />
            </div>
          </div>

          {/* Text on right */}
          <div className="lg:col-span-5 space-y-4 text-left order-1 lg:order-2">
            <span className="text-[12px] font-semibold text-apple-primary tracking-widest uppercase">LIMITS</span>
            <h3 className="font-sans text-apple-ink font-semibold text-[32px] sm:text-[40px] leading-tight tracking-tight">
              {t('screenshots.screen2')}
            </h3>
            <p className="text-[17px] text-apple-ink/70 leading-relaxed font-light">
              Get intelligent limits on your categories. CuanBuddy monitors your spending pace and alerts you before reaching your limit.
            </p>
            <div className="pt-2">
              <a href="#features" className="inline-flex items-center text-apple-primary hover:underline text-[17px] font-normal gap-0.5">
                Learn more about budgets <ChevronRight size={16} />
              </a>
            </div>
          </div>
        </div>
      </div>

      {/* Tile 3: Saving Goals Tracker (Apple Light Tile style) */}
      <div className="bg-white py-16 border-b border-hairline/60 overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          <div className="lg:col-span-5 space-y-4 text-left">
            <span className="text-[12px] font-semibold text-apple-primary tracking-widest uppercase">SAVINGS</span>
            <h3 className="font-sans text-apple-ink font-semibold text-[32px] sm:text-[40px] leading-tight tracking-tight">
              {t('screenshots.screen3')}
            </h3>
            <p className="text-[17px] text-apple-ink/70 leading-relaxed font-light">
              Track milestones, customize icons, and receive tips to accelerate your saving progress.
            </p>
            <div className="pt-2">
              <a href="#features" className="inline-flex items-center text-apple-primary hover:underline text-[17px] font-normal gap-0.5">
                Learn more about goals <ChevronRight size={16} />
              </a>
            </div>
          </div>
          
          {/* Mock Mobile App screen using image */}
          <div className="lg:col-span-7 flex justify-center">
            <div className="w-[300px] h-[550px] rounded-[32px] bg-apple-ink border-[8px] border-apple-ink shadow-apple-product overflow-hidden relative">
              <img 
                src="/app_screen_mockup.png" 
                alt="Savings Screen Mockup" 
                className="w-full h-full object-cover rounded-[24px]"
                onError={(e) => { e.currentTarget.src = "/app_icon_transparent.png"; }}
              />
            </div>
          </div>
        </div>
      </div>

    </section>
  );
}
export {};
