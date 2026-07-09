import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useTheme } from './ThemeProvider';
import { Moon, Sun, Globe } from 'lucide-react';

export default function Navbar() {
  const { t, i18n } = useTranslation();
  const { theme, setTheme } = useTheme();
  const [activeSection, setActiveSection] = useState('');

  useEffect(() => {
    const handleScroll = () => {
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
    // trigger once on mount
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
    <nav className="fixed w-full top-0 z-50 bg-background/80 backdrop-blur-md border-b border-border transition-colors duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between items-center h-16">
          <div className="flex items-center gap-2">
            <img src="/app_icon_transparent.png" alt="CuanBuddy" className="h-8 w-8" />
            <span className="font-bold text-xl text-primary">CuanBuddy</span>
          </div>
          
          <div className="hidden md:flex items-center space-x-8 font-medium">
            <a href="#features" className={`transition-colors ${activeSection === 'features' ? 'text-primary font-bold' : 'hover:text-primary'}`}>{t('nav.features')}</a>
            <a href="#how" className={`transition-colors ${activeSection === 'how' ? 'text-primary font-bold' : 'hover:text-primary'}`}>{t('nav.howItWorks')}</a>
            <a href="#testimonials" className={`transition-colors ${activeSection === 'testimonials' ? 'text-primary font-bold' : 'hover:text-primary'}`}>{t('nav.testimonials')}</a>
            <a href="#faq" className={`transition-colors ${activeSection === 'faq' ? 'text-primary font-bold' : 'hover:text-primary'}`}>{t('nav.faq')}</a>
          </div>

          <div className="flex items-center gap-2 sm:gap-4">
            <button onClick={toggleLanguage} className="p-2 rounded-full hover:bg-border transition-colors flex items-center gap-1" aria-label="Toggle Language">
              <Globe size={20} />
              <span className="text-sm font-bold uppercase">{i18n.language}</span>
            </button>
            <button onClick={toggleTheme} className="p-2 rounded-full hover:bg-border transition-colors" aria-label="Toggle Theme">
              {theme === 'dark' ? <Sun size={20} /> : <Moon size={20} />}
            </button>
          </div>
        </div>
      </div>
    </nav>
  );
}
