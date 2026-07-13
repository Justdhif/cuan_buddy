import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Globe } from 'lucide-react';

export default function Navbar() {
  const { t, i18n } = useTranslation();
  const [activeSection, setActiveSection] = useState('');
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 20) {
        setScrolled(true);
      } else {
        setScrolled(false);
      }

      const sections = ['features', 'how', 'testimonials', 'faq'];
      const scrollPosition = window.scrollY + 100;

      let current = '';
      sections.forEach((section) => {
        const element = document.getElementById(section);
        if (element && element.offsetTop <= scrollPosition) {
          current = section;
        }
      });
      setActiveSection(current);
    };

    window.addEventListener('scroll', handleScroll);
    handleScroll();
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const toggleLanguage = () => {
    const newLang = i18n.language === 'id' ? 'en' : 'id';
    i18n.changeLanguage(newLang);
  };

  return (
    <nav 
      className={`fixed w-full top-0 z-50 transition-all duration-300 ${
        scrolled 
          ? 'bg-white/80 border-b border-hairline/80 backdrop-blur-md py-3 shadow-xs' 
          : 'bg-transparent border-b border-transparent py-5'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-12">
          {/* Logo & Brand */}
          <div className="flex items-center gap-2">
            <img src="/app_icon_transparent.png" alt="CuanBuddy Logo" className="h-7 w-7" />
            <span className="font-semibold text-[18px] text-ink tracking-tight">CuanBuddy</span>
          </div>
          
          {/* Center Navigation */}
          <div className="hidden md:flex items-center space-x-8 text-[14px] font-medium">
            <a 
              href="#features" 
              className={`transition-colors duration-200 ${
                activeSection === 'features' 
                  ? 'text-primary font-semibold' 
                  : 'text-ink/70 hover:text-primary'
              }`}
            >
              {t('nav.features')}
            </a>
            <a 
              href="#how" 
              className={`transition-colors duration-200 ${
                activeSection === 'how' 
                  ? 'text-primary font-semibold' 
                  : 'text-ink/70 hover:text-primary'
              }`}
            >
              {t('nav.howItWorks')}
            </a>
            <a 
              href="#testimonials" 
              className={`transition-colors duration-200 ${
                activeSection === 'testimonials' 
                  ? 'text-primary font-semibold' 
                  : 'text-ink/70 hover:text-primary'
              }`}
            >
              {t('nav.testimonials')}
            </a>
            <a 
              href="#faq" 
              className={`transition-colors duration-200 ${
                activeSection === 'faq' 
                  ? 'text-primary font-semibold' 
                  : 'text-ink/70 hover:text-primary'
              }`}
            >
              {t('nav.faq')}
            </a>
          </div>

          {/* Right Controls / CTA */}
          <div className="flex items-center gap-1.5 sm:gap-2">
            <button 
              onClick={toggleLanguage} 
              className="p-2 rounded-full hover:bg-black/5 text-ink/70 hover:text-ink transition-colors flex items-center gap-1" 
              aria-label="Toggle Language"
            >
              <Globe size={16} />
              <span className="text-[11px] font-bold uppercase">{i18n.language}</span>
            </button>

            <a 
              href="#download" 
              className="inline-flex items-center justify-center bg-primary hover:bg-primary-deep text-white text-[13px] font-semibold rounded-full px-4 py-2 shadow-sm transition-all duration-200 active:scale-95"
            >
              {t('nav.download')}
            </a>
          </div>
        </div>
      </div>
    </nav>
  );
}
export {};
