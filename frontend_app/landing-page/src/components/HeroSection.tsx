import { useTranslation } from 'react-i18next';
import { ArrowRight } from 'lucide-react';

export default function HeroSection() {
  const { t } = useTranslation();

  return (
    <section className="relative min-h-screen flex items-center justify-center pt-16 overflow-hidden">
      {/* Background Gradients */}
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,var(--color-primary)_0%,transparent_50%)] opacity-20 dark:opacity-10 pointer-events-none"></div>
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom,var(--color-accent)_0%,transparent_50%)] opacity-20 dark:opacity-10 pointer-events-none"></div>

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center flex flex-col items-center">
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-border/50 backdrop-blur-sm border border-border text-sm font-bold mb-8 shadow-sm">
          <span className="flex h-2.5 w-2.5 rounded-full bg-secondary"></span>
          CuanBuddy V1.0 is Live
        </div>
        
        <h1 className="text-5xl md:text-7xl font-extrabold tracking-tight mb-6 max-w-4xl mx-auto leading-tight">
          {t('hero.title').split(' ').map((word: string, i: number) => (
            i === 0 ? <span key={i} className="text-transparent bg-clip-text bg-linear-to-r from-primary to-accent">{word} </span> : <span key={i}>{word} </span>
          ))}
        </h1>
        
        <p className="text-xl md:text-2xl text-foreground/70 max-w-2xl mx-auto mb-10 leading-relaxed font-medium">
          {t('hero.subtitle')}
        </p>

        <div className="flex flex-col sm:flex-row gap-4 items-center justify-center w-full sm:w-auto">
          <button className="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-4 bg-foreground text-background font-bold rounded-full hover:opacity-90 transition-all transform hover:scale-105 shadow-xl">
            {t('hero.cta')}
            <ArrowRight size={20} />
          </button>
          <a href="#how" className="w-full sm:w-auto flex items-center justify-center gap-2 px-8 py-4 bg-card border-2 border-border font-bold rounded-full hover:bg-border/50 transition-all">
            {t('nav.howItWorks')}
          </a>
        </div>
      </div>


    </section>
  );
}
