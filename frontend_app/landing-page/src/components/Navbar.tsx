import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useTheme } from './ThemeProvider';
import { Moon, Sun, Globe } from 'lucide-react';

export default function Navbar() {
  const { t, i18n } = useTranslation();
  const { theme, setTheme } = useTheme();
  const [activeSection, setActiveSection] = useState('');
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      // Toggle scrolled background
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

  const toggleTheme = () => {
    const isSystemDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    const currentTheme = theme === 'system' ? (isSystemDark ? 'dark' : 'light') : theme;
    setTheme(currentTheme === 'dark' ? 'light' : 'dark');
  };

  return (
    <nav 
      className={`fixed w-full top-0 z-50 transition-all duration-300 ${
        scrolled 
          ? 'bg-canvas/80 dark:bg-brand-dark-900/80 backdrop-blur-md border-b border-hairline/60 dark:border-hairline/10 py-3' 
          : 'bg-transparent py-5'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-12">
          {/* Logo & Brand */}
          <div className="flex items-center gap-2">
            <img src="/app_icon_transparent.png" alt="CuanBuddy Logo" className="h-7 w-7" />
            <span className="font-semibold text-lg text-ink dark:text-canvas tracking-tight">CuanBuddy</span>
          </div>
          
          {/* Center Navigation */}
          <div className="hidden md:flex items-center space-x-8 text-[15px] font-normal text-ink-secondary dark:text-canvas/85">
            <a 
              href="#features" 
              className={`transition-colors duration-200 ${
                activeSection === 'features' 
                  ? 'text-primary dark:text-primary-soft font-medium' 
                  : 'hover:text-primary dark:hover:text-primary-soft'
              }`}
            >
              {t('nav.features')}
            </a>
            <a 
              href="#how" 
              className={`transition-colors duration-200 ${
                activeSection === 'how' 
                  ? 'text-primary dark:text-primary-soft font-medium' 
                  : 'hover:text-primary dark:hover:text-primary-soft'
              }`}
            >
              {t('nav.howItWorks')}
            </a>
            <a 
              href="#testimonials" 
              className={`transition-colors duration-200 ${
                activeSection === 'testimonials' 
                  ? 'text-primary dark:text-primary-soft font-medium' 
                  : 'hover:text-primary dark:hover:text-primary-soft'
              }`}
            >
              {t('nav.testimonials')}
            </a>
            <a 
              href="#faq" 
              className={`transition-colors duration-200 ${
                activeSection === 'faq' 
                  ? 'text-primary dark:text-primary-soft font-medium' 
                  : 'hover:text-primary dark:hover:text-primary-soft'
              }`}
            >
              {t('nav.faq')}
            </a>
          </div>

          {/* Right Controls / CTA */}
          <div className="flex items-center gap-2 sm:gap-3">
            <button 
              onClick={toggleLanguage} 
              className="p-2 rounded-full hover:bg-canvas-soft dark:hover:bg-brand-dark-900 text-ink-mute dark:text-canvas/70 transition-colors flex items-center gap-1" 
              aria-label="Toggle Language"
            >
              <Globe size={18} />
              <span className="text-[12px] font-semibold uppercase">{i18n.language}</span>
            </button>
            
            <button 
              onClick={toggleTheme} 
              className="p-2 rounded-full hover:bg-canvas-soft dark:hover:bg-brand-dark-900 text-ink-mute dark:text-canvas/70 transition-colors" 
              aria-label="Toggle Theme"
            >
              {theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
            </button>

            <a 
              href="#download" 
              className="hidden sm:inline-flex items-center justify-center bg-primary hover:bg-primary-deep text-on-primary text-[14px] font-medium rounded-full px-4 py-2 shadow-level-1 transition-all duration-200 active:bg-primary-press"
            >
              Get Started
            </a>
          </div>
        </div>
      </div>
    </nav>
  );
}
